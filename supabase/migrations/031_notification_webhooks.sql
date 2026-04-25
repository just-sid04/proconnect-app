-- Migration: 031_notification_webhooks.sql
-- Goal: Automate notification creation and support FCM push tokens.

-- 1. Add fcm_token to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. Notification Creation Function
CREATE OR REPLACE FUNCTION public.create_app_notification()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    notif_title TEXT;
    notif_body TEXT;
    notif_type TEXT;
BEGIN
    -- HANDLE BOOKINGS
    IF (TG_TABLE_NAME = 'bookings') THEN
        IF (TG_OP = 'INSERT') THEN
            target_user_id := NEW.provider_id;
            notif_title := 'New Booking Request';
            notif_body := 'You have a new booking request for ' || NEW.description;
            notif_type := 'booking_request';
        ELSIF (TG_OP = 'UPDATE' AND OLD.status <> NEW.status) THEN
            target_user_id := NEW.customer_id;
            notif_type := 'booking_status';
            IF (NEW.status = 'accepted') THEN
                notif_title := 'Booking Accepted';
                notif_body := 'Your booking has been accepted by the provider.';
            ELSIF (NEW.status = 'completed') THEN
                notif_title := 'Booking Completed';
                notif_body := 'Service is done! Please leave a review.';
            ELSIF (NEW.status = 'cancelled') THEN
                notif_title := 'Booking Cancelled';
                notif_body := 'Your booking was cancelled.';
            ELSE
                RETURN NEW;
            END IF;
        ELSE
            RETURN NEW;
        END IF;

    -- HANDLE MESSAGES
    ELSIF (TG_TABLE_NAME = 'messages') THEN
        IF (NEW.sender_id = NEW.customer_id) THEN
            target_user_id := NEW.provider_user_id;
        ELSE
            target_user_id := NEW.customer_id;
        END IF;
        notif_title := 'New Message';
        notif_body := NEW.content;
        notif_type := 'chat';
    END IF;

    -- Insert into notifications table
    INSERT INTO public.notifications (user_id, title, body, type, data)
    VALUES (
        target_user_id,
        notif_title,
        notif_body,
        notif_type,
        jsonb_build_object('id', NEW.id)
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create Triggers
DROP TRIGGER IF EXISTS on_booking_notification ON public.bookings;
CREATE TRIGGER on_booking_notification
    AFTER INSERT OR UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.create_app_notification();

DROP TRIGGER IF EXISTS on_message_notification ON public.messages;
CREATE TRIGGER on_message_notification
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.create_app_notification();

-- 4. Hook for Push Notifications (Webhooks)
-- This trigger will be picked up by the Supabase Edge Function via Webhook
-- You should configure the Webhook in the Supabase Dashboard to point to 
-- your 'send-push' Edge Function.

CREATE OR REPLACE FUNCTION public.notify_push_service()
RETURNS TRIGGER AS $$
BEGIN
  -- This function is a placeholder for the payload
  -- The actual delivery happens via Supabase Webhooks calling an Edge Function
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_new_notification_push ON public.notifications;
CREATE TRIGGER on_new_notification_push
    AFTER INSERT ON public.notifications
    FOR EACH ROW EXECUTE FUNCTION public.notify_push_service();
