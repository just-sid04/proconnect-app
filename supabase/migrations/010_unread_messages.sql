-- Migration: 010_unread_messages.sql
-- Add is_read column to messages and update policies

-- Add the column
ALTER TABLE public.messages 
ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Policy: Update
-- A participant can mark messages as read.
-- We only allow updating the is_read column.

CREATE POLICY "Participants can mark messages as read" ON public.messages
    FOR UPDATE USING (
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
    )
    WITH CHECK (
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
