-- Migration: 020_optimized_search.sql
-- Goal: Update geospatial search to include online status, availability checks, and activity ranking.

-- Drop existing versions to avoid ambiguity with overloaded signatures (4 and 5 arguments)
DROP FUNCTION IF EXISTS public.get_nearby_providers(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, UUID);
DROP FUNCTION IF EXISTS public.get_nearby_providers(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, UUID, BOOLEAN);

CREATE OR REPLACE FUNCTION public.get_nearby_providers(
  current_lat DOUBLE PRECISION,
  current_lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 10,
  target_category_id UUID DEFAULT NULL,
  only_online BOOLEAN DEFAULT true
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
  distance_km DOUBLE PRECISION,
  is_online BOOLEAN,
  last_active_at TIMESTAMPTZ,
  is_available_now BOOLEAN
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
    -- Distance calculation using PostGIS
    (st_distance_sphere(
      st_makePoint(current_lng, current_lat),
      st_makePoint(p.longitude, p.latitude)
    ) / 1000.0) as distance_km,
    sp.is_online,
    sp.last_active_at,
    -- Check if available right now (based on schedule)
    public.check_provider_availability(sp.id, now(), 1) as is_available_now
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
    AND (NOT only_online OR sp.is_online = true)
    -- Filter by radius
    AND st_distance_sphere(
      st_makePoint(current_lng, current_lat),
      st_makePoint(p.longitude, p.latitude)
    ) <= radius_km * 1000
  ORDER BY 
    sp.is_online DESC,
    is_available_now DESC,
    distance_km ASC,
    sp.last_active_at DESC;
END;
$$;

COMMENT ON FUNCTION public.get_nearby_providers IS 'Searches for providers with PostGIS radius filtering, online status, and availability ranking.';
