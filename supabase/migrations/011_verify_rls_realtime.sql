-- Migration 011: Final APK Stability Fixes (RLS & Realtime)
-- Run this in your Supabase SQL Editor to ensure production consistency.

-- 1. Ensure Profiles are readable by all authenticated users.
-- This is critical for the Booking section loading because it joins customer/provider profiles.
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;

CREATE POLICY "Authenticated users can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- 2. Ensure Bookings table is enabled for Realtime.
-- Without this, the app won't see status changes instantly.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;
END $$;

-- 3. Verify Service Providers are readable.
DROP POLICY IF EXISTS "Service providers viewable by everyone" ON public.service_providers;
CREATE POLICY "Service providers viewable by everyone"
  ON public.service_providers
  FOR SELECT
  USING (true);

-- 4. Add index for faster booking lookups (if not already present).
CREATE INDEX IF NOT EXISTS idx_bookings_provider_composite ON public.bookings(provider_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_customer_composite ON public.bookings(customer_id, status);
