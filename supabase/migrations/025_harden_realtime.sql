-- Migration: 025_harden_realtime.sql
-- Goal: Ensure the messages table has the correct configuration for reliable realtime delivery.

-- 1. Enable Full Replica Identity
-- This ensures that all column values (including OLD) are sent in the realtime stream.
-- While mostly needed for updates/deletes, it's a best practice for reliable sync.
ALTER TABLE public.messages REPLICA IDENTITY FULL;

-- 2. Ensure the table is in the supabase_realtime publication
-- This is idempotent (Safe to run even if already added).
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'messages'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
    END IF;
END $$;
