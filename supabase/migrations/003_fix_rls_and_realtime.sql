-- =============================================
-- Migration 003: Fix RLS for cross-user reads + enable Realtime
-- Run this in Supabase SQL Editor
-- =============================================

-- PROBLEM 1: The profiles RLS SELECT policy only allows users to read THEIR OWN
-- profile (auth.uid() = id). This means when customer bookings try to join the
-- provider's profile (or vice versa), the join silently returns NULL or fails.
-- FIX: Allow any authenticated user to read any profile (names/photos are not sensitive).

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

CREATE POLICY "Authenticated users can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Keep insert/update restricted to own profile
-- (those policies already exist from migration 001)


-- PROBLEM 2: Supabase Realtime requires tables to be added to the supabase_realtime
-- publication. Without this, the .channel().onPostgresChanges() listener never fires.
-- FIX: Add the bookings table to the realtime publication.

-- Drop and recreate to ensure bookings is included
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;
END $$;


-- PROBLEM 3: Customers need to be able to update their own bookings status
-- (e.g., cancel). The existing UPDATE policy only covers providers.
-- FIX: Already exists in 001 as "Customers can update own bookings" — verify it's there.
-- If it wasn't applied, run:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'bookings'
      AND policyname = 'Customers can update own bookings'
  ) THEN
    CREATE POLICY "Customers can update own bookings" ON public.bookings
      FOR UPDATE USING (customer_id = auth.uid());
  END IF;
END $$;
