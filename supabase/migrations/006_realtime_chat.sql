-- Step 2: Real-Time In-App Chat
-- Migration: 006_realtime_chat.sql

-- =============================================
-- MESSAGES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- REALTIME
-- =============================================
-- Enable realtime for messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Policy: Select
-- A user can read messages for a booking if they are the customer or the provider.
CREATE POLICY "Participants can view booking messages" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = messages.booking_id AND (
                b.customer_id = auth.uid() OR
                COALESCE(
                    b.provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()),
                    false
                )
            )
        )
    );

-- Policy: Insert
-- A user can send a message if they are a participant and the sender_id matches their auth.uid().
CREATE POLICY "Participants can send messages" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id AND (
                b.customer_id = auth.uid() OR
                COALESCE(
                    b.provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()),
                    false
                )
            )
        )
    );

-- =============================================
-- INDEXES
-- =============================================
CREATE INDEX IF NOT EXISTS idx_messages_booking ON public.messages(booking_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages(created_at);
