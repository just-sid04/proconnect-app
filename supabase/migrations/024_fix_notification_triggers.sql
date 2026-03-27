-- Migration: 024_fix_notification_triggers.sql
-- Goal: Fix FK violations and logical errors in notification triggers.

-- 1. Relax/Fix notifications FK constraint
-- Moving it to profiles(id) is more reliable since our triggers use profiles context
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE public.notifications 
    ADD CONSTRAINT notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 2. Improved Booking Notification Trigger Function
CREATE OR REPLACE FUNCTION public.handle_booking_notification()
RETURNS TRIGGER AS $$
DECLARE
    customer_name TEXT;
    provider_name TEXT;
    provider_user_id UUID;
    v_title TEXT;
    v_body TEXT;
    v_type TEXT := 'booking';
BEGIN
    -- Get names and the actual USER ID of the provider
    SELECT name INTO customer_name FROM public.profiles WHERE id = NEW.customer_id;
    
    -- Resolve provider's user_id from service_providers table
    SELECT name, user_id INTO provider_name, provider_user_id 
    FROM public.profiles p
    JOIN public.service_providers sp ON sp.user_id = p.id
    WHERE sp.id = NEW.provider_id;

    -- Scenario A: New Booking (Insert)
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.notifications (user_id, title, body, type, data)
        VALUES (
            provider_user_id, -- Corrected from NEW.provider_id
            'New Booking Request',
            customer_name || ' wants to book your service.',
            v_type,
            jsonb_build_object('booking_id', NEW.id, 'screen', 'booking_details')
        );
    
    -- Scenario B: Status Update
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Provider accepted -> Notify Customer
        IF (NEW.status = 'accepted' AND OLD.status = 'pending') THEN
            INSERT INTO public.notifications (user_id, title, body, type, data)
            VALUES (
                NEW.customer_id,
                'Booking Accepted!',
                provider_name || ' is ready to help you.',
                v_type,
                jsonb_build_object('booking_id', NEW.id, 'screen', 'booking_details')
            );
        
        -- Service Started -> Notify Customer
        ELSIF (NEW.status = 'in_progress' AND OLD.status = 'accepted') THEN
            INSERT INTO public.notifications (user_id, title, body, type, data)
            VALUES (
                NEW.customer_id,
                'Service Started',
                'Your session with ' || provider_name || ' has begun.',
                v_type,
                jsonb_build_object('booking_id', NEW.id, 'screen', 'booking_details')
            );

        -- Service Completed -> Notify Customer
        ELSIF (NEW.status = 'completed' AND OLD.status = 'in_progress') THEN
            INSERT INTO public.notifications (user_id, title, body, type, data)
            VALUES (
                NEW.customer_id,
                'Service Completed',
                'Your booking is done. Please pay the remaining balance.',
                v_type,
                jsonb_build_object('booking_id', NEW.id, 'screen', 'booking_details')
            );
        END IF;

        -- Payment Updates (Advance/Final)
        IF (NEW.advance_paid = true AND (OLD.advance_paid = false OR OLD.advance_paid IS NULL)) THEN
            INSERT INTO public.notifications (user_id, title, body, type, data)
            VALUES (
                provider_user_id,
                'Advance Paid',
                'Customer has paid the 20% advance for booking #' || substr(NEW.id::text, 1, 8),
                'payment',
                jsonb_build_object('booking_id', NEW.id, 'screen', 'booking_details')
            );
        END IF;

        IF (NEW.final_paid = true AND (OLD.final_paid = false OR OLD.final_paid IS NULL)) THEN
            INSERT INTO public.notifications (user_id, title, body, type, data)
            VALUES (
                provider_user_id,
                'Payment Received',
                'Final payment received for booking #' || substr(NEW.id::text, 1, 8),
                'payment',
                jsonb_build_object('booking_id', NEW.id, 'screen', 'booking_details')
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Improved Message Notification Trigger Function
CREATE OR REPLACE FUNCTION public.handle_message_notification()
RETURNS TRIGGER AS $$
DECLARE
    sender_name TEXT;
    target_user_id UUID;
BEGIN
    -- Get sender name
    SELECT name INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

    -- Dynamically find the receiver (the other participant in the booking)
    -- This avoids having to add a receiver_id column to the messages table
    SELECT 
        CASE 
            WHEN b.customer_id = NEW.sender_id THEN (SELECT user_id FROM public.service_providers WHERE id = b.provider_id)
            ELSE b.customer_id
        END INTO target_user_id
    FROM public.bookings b
    WHERE b.id = NEW.booking_id;

    IF (target_user_id IS NOT NULL) THEN
        INSERT INTO public.notifications (user_id, title, body, type, data)
        VALUES (
            target_user_id,
            'New Message from ' || sender_name,
            NEW.text, -- Table uses 'text', not 'content'
            'chat',
            jsonb_build_object(
                'booking_id', NEW.booking_id, 
                'screen', 'chat',
                'other_user_name', sender_name
            )
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
