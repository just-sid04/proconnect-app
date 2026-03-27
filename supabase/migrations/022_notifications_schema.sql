-- Migration: 022_notifications_schema.sql
-- Goal: Unified notification system with automated triggers.

-- 1. Create Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('booking', 'payment', 'chat', 'system')),
    is_read BOOLEAN DEFAULT false,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high')),
    data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications."
ON public.notifications FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications (mark as read)."
ON public.notifications FOR UPDATE
USING (auth.uid() = user_id);

-- 3. Trigger Function for Booking Events
CREATE OR REPLACE FUNCTION public.handle_booking_notification()
RETURNS TRIGGER AS $$
DECLARE
    customer_name TEXT;
    provider_name TEXT;
    target_user_id UUID;
    v_title TEXT;
    v_body TEXT;
    v_type TEXT := 'booking';
BEGIN
    -- Get names for better notification text
    SELECT name INTO customer_name FROM public.profiles WHERE id = NEW.customer_id;
    SELECT name INTO provider_name FROM public.profiles WHERE id = NEW.provider_id;

    -- Scenario A: New Booking (Insert)
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.notifications (user_id, title, body, type, data)
        VALUES (
            NEW.provider_id,
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
        IF (NEW.advance_paid = true AND OLD.advance_paid = false) THEN
            INSERT INTO public.notifications (user_id, title, body, type, data)
            VALUES (
                NEW.provider_id,
                'Advance Paid',
                'Customer has paid the 20% advance for booking #' || substr(NEW.id::text, 1, 8),
                'payment',
                jsonb_build_object('booking_id', NEW.id, 'screen', 'booking_details')
            );
        END IF;

        IF (NEW.final_paid = true AND OLD.final_paid = false) THEN
            INSERT INTO public.notifications (user_id, title, body, type, data)
            VALUES (
                NEW.provider_id,
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

-- 4. Apply Triggers
DROP TRIGGER IF EXISTS tr_on_booking_change ON public.bookings;
CREATE TRIGGER tr_on_booking_change
AFTER INSERT OR UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.handle_booking_notification();

-- 5. Trigger for New Messages
CREATE OR REPLACE FUNCTION public.handle_message_notification()
RETURNS TRIGGER AS $$
DECLARE
    sender_name TEXT;
BEGIN
    SELECT name INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

    INSERT INTO public.notifications (user_id, title, body, type, data)
    VALUES (
        NEW.receiver_id,
        'New Message from ' || sender_name,
        NEW.content,
        'chat',
        jsonb_build_object(
            'booking_id', NEW.booking_id, 
            'screen', 'chat',
            'other_user_name', sender_name
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_on_new_message ON public.messages;
CREATE TRIGGER tr_on_new_message
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.handle_message_notification();
