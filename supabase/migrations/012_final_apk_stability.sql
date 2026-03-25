-- Migration 012: Final APK Stability (RLS & Realtime Consolidation)
-- Run this in your Supabase SQL Editor to ensure production consistency.

-- 1. PROFILES: Ensure all authenticated users can read profiles (needed for Joins)
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;

CREATE POLICY "Authenticated users can view all profiles"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() IS NOT NULL);


-- 2. SERVICE PROVIDERS: Ensure all users can read provider info (needed for Joins)
DROP POLICY IF EXISTS "Service providers viewable by everyone" ON public.service_providers;
DROP POLICY IF EXISTS "Service providers are viewable by everyone" ON public.service_providers;

CREATE POLICY "Service providers viewable by everyone"
  ON public.service_providers
  FOR SELECT
  USING (true);


-- 3. BOOKINGS: Robust SELECT policy for both Customers and Providers
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Involved users can view bookings" ON public.bookings;

CREATE POLICY "Involved users can view bookings"
  ON public.bookings
  FOR SELECT
  USING (
    customer_id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM public.service_providers 
      WHERE id = bookings.provider_id AND user_id = auth.uid()
    )
  );


-- 4. REALTIME: Ensure Bookings is in the publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;
END $$;


-- 5. PERFORMANCE: Added composite indexes for common dashboard filters
CREATE INDEX IF NOT EXISTS idx_bookings_lookup_customer ON public.bookings(customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_lookup_provider ON public.bookings(provider_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_status_composite ON public.bookings(status, created_at DESC);
