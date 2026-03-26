-- Migration: Add Geospatial fields for ProConnect Evolution
-- Description: Adds lat/lng coordinates to profiles (for service areas) and bookings (for job locations).

-- 1. Update Profiles table
-- latitude/longitude represent the center of the provider's service area or customer's home.
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 2. Update Bookings table
-- latitude/longitude represent the exact location where the service is requested.
ALTER TABLE public.bookings
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 3. Add a Service Radius column for providers (in kilometers)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS service_radius DOUBLE PRECISION DEFAULT 20.0;

-- 4. Enable PostGIS (Optional but highly recommended for Phase 4 distance queries)
-- This requires superuser or specific extension permissions on Supabase.
-- If this fails, we can still use manual Haversine math.
CREATE EXTENSION IF NOT EXISTS postgis;

-- 5. Add index for faster spatial lookups if PostGIS is enabled
-- We'll use simple double precision for now to keep it easy for Phase 1.
CREATE INDEX IF NOT EXISTS idx_profiles_location ON public.profiles (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_bookings_location ON public.bookings (latitude, longitude);

-- 6. Update handle_new_user trigger to save latitude and longitude from metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into profiles
  INSERT INTO public.profiles (id, name, email, phone, role, latitude, longitude, service_radius, location)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    (NEW.raw_user_meta_data->>'latitude')::DOUBLE PRECISION,
    (NEW.raw_user_meta_data->>'longitude')::DOUBLE PRECISION,
    COALESCE((NEW.raw_user_meta_data->>'service_radius')::DOUBLE PRECISION, 20.0),
    NEW.raw_user_meta_data->'location'
  );

  -- If provider, also create a record in service_providers
  IF (NEW.raw_user_meta_data->>'role' = 'provider') THEN
    INSERT INTO public.service_providers (
      user_id,
      category_id,
      hourly_rate,
      description,
      is_verified
    ) VALUES (
      NEW.id,
      COALESCE((NEW.raw_user_meta_data->>'categoryId')::UUID, '11111111-1111-1111-1111-111111111105'::UUID), -- Default to Home Maintenance if not provided
      COALESCE((NEW.raw_user_meta_data->>'hourlyRate')::NUMERIC, 0),
      COALESCE(NEW.raw_user_meta_data->>'description', 'Professional Service Provider'),
      false
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
