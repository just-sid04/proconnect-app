-- Migration: Geospatial Search RPC
-- Description: Adds a function to search for providers within a specific radius using PostGIS.

-- Enable PostGIS if not already enabled (this is repeated for safety)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Create a function to search for providers within a radius
-- This function uses latitude and longitude from the profiles table.
CREATE OR REPLACE FUNCTION public.get_nearby_providers(
  current_lat DOUBLE PRECISION,
  current_lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 10,
  target_category_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  name TEXT,
  email TEXT,
  profile_photo TEXT,
  category_id UUID,
  category_name TEXT,
  hourly_rate NUMERIC,
  rating NUMERIC,
  total_reviews INT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  distance_km DOUBLE PRECISION
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sp.id,
    p.id as user_id,
    p.name,
    p.email,
    p.profile_photo,
    sp.category_id,
    cat.name as category_name,
    sp.hourly_rate,
    sp.rating,
    sp.total_reviews,
    p.latitude,
    p.longitude,
    -- Distance calculation using PostGIS st_distance_sphere (meters to km)
    (st_distance_sphere(
      st_makePoint(current_lng, current_lat),
      st_makePoint(p.longitude, p.latitude)
    ) / 1000.0) as distance_km
  FROM 
    public.service_providers sp
  JOIN 
    public.profiles p ON sp.user_id = p.id
  JOIN 
    public.categories cat ON sp.category_id = cat.id
  WHERE 
    p.is_active = true
    AND sp.verification_status = 'approved'
    AND p.latitude IS NOT NULL 
    AND p.longitude IS NOT NULL
    AND (target_category_id IS NULL OR sp.category_id = target_category_id)
    -- Filter by radius
    AND st_distance_sphere(
      st_makePoint(current_lng, current_lat),
      st_makePoint(p.longitude, p.latitude)
    ) <= radius_km * 1000
  ORDER BY 
    distance_km ASC;
END;
$$;

-- 2. Add a policy for the function if needed (RPCs are usually public but restricted by the function's own logic)
-- EXPLAIN ANALYZE can be used to verify the index is used.
