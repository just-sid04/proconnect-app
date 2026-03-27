-- Migration: 027_flatten_chat_rls.sql
-- Goal: Flatten message permissions to fix Realtime subscription issues.

-- 1. Add participant columns to messages for direct RLS (No subqueries)
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.profiles(id);
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS provider_user_id UUID REFERENCES public.profiles(id);

-- 2. Create a function to automatically populate these columns from the booking
CREATE OR REPLACE FUNCTION public.populate_message_participants()
RETURNS TRIGGER AS $$
BEGIN
    SELECT 
        b.customer_id, 
        (SELECT user_id FROM public.service_providers sp WHERE sp.id = b.provider_id)
    INTO 
        NEW.customer_id, 
        NEW.provider_user_id
    FROM public.bookings b
    WHERE b.id = NEW.booking_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Apply the BEFORE INSERT trigger
DROP TRIGGER IF EXISTS tr_populate_message_participants ON public.messages;
CREATE TRIGGER tr_populate_message_participants
BEFORE INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.populate_message_participants();

-- 4. Backfill existing messages (optional but good for history)
UPDATE public.messages m
SET 
    customer_id = b.customer_id,
    provider_user_id = (SELECT user_id FROM public.service_providers sp WHERE sp.id = b.provider_id)
FROM public.bookings b
WHERE m.booking_id = b.id
AND (m.customer_id IS NULL OR m.provider_user_id IS NULL);

-- 5. REVOLUTIONARY SIMPLE RLS POLICY
-- This policy uses NO subqueries, making it 100% reliable for Realtime.
DROP POLICY IF EXISTS "Participants can view booking messages" ON public.messages;
CREATE POLICY "Participants can view booking messages" ON public.messages
FOR SELECT
TO authenticated
USING (
    auth.uid() = sender_id OR 
    auth.uid() = customer_id OR 
    auth.uid() = provider_user_id
);

-- Ensure other participants can INSERT too (with the trigger handling validation)
DROP POLICY IF EXISTS "Participants can send messages" ON public.messages;
CREATE POLICY "Participants can send messages" ON public.messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM public.bookings b
        WHERE b.id = booking_id AND (
            b.customer_id = auth.uid() OR
            b.provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid())
        )
    )
);

-- 6. Ensure publication is still active
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER TABLE public.messages REPLICA IDENTITY FULL;
