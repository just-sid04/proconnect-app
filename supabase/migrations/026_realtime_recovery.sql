-- Migration: 026_realtime_recovery.sql
-- Goal: Fix realtimesubscribeerror by resetting publication and simplifying RLS.

-- 1. Reset Realtime Publication
-- This is sometimes necessary if the publication state gets corrupted.
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime FOR TABLE public.messages, public.notifications, public.bookings;

-- 2. Simplify RLS for Messages
-- Complex EXISTS/Subqueries can cause issues with Realtime streams.
-- We use a simpler "IN" structure which is more friendly to the engine.
DROP POLICY IF EXISTS "Participants can view booking messages" ON public.messages;
CREATE POLICY "Participants can view booking messages" ON public.messages
FOR SELECT
TO authenticated
USING (
  sender_id = auth.uid() OR
  booking_id IN (
    SELECT b.id FROM public.bookings b
    LEFT JOIN public.service_providers sp ON sp.id = b.provider_id
    WHERE b.customer_id = auth.uid() OR sp.user_id = auth.uid()
  )
);

-- 3. Ensure Replica Identity is set to FULL
ALTER TABLE public.messages REPLICA IDENTITY FULL;
ALTER TABLE public.notifications REPLICA IDENTITY FULL;

-- 4. Grant Realtime permissions to authenticated users (just in case)
GRANT SELECT ON public.messages TO authenticated;
GRANT SELECT ON public.notifications TO authenticated;
