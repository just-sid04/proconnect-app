-- Migration: Smart Category Recommendations
-- Description: Adds an RPC to get personalized category recommendations for a user.

CREATE OR REPLACE FUNCTION public.get_user_recommendations(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  icon TEXT,
  color TEXT,
  services JSONB,
  average_rate NUMERIC,
  total_providers INT,
  is_active BOOLEAN
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH user_history AS (
    -- 1. Categories the user has booked before
    SELECT 
      category_id, 
      count(*) as booking_count
    FROM 
      public.bookings
    WHERE 
      customer_id = p_user_id
    GROUP BY 
      category_id
  ),
  popular_categories AS (
    -- 2. Overall popular categories platform-wide
    SELECT 
      category_id, 
      count(*) as global_count
    FROM 
      public.bookings
    GROUP BY 
      category_id
    ORDER BY 
      global_count DESC
    LIMIT 5
  ),
  recommended_ids AS (
    -- Combine with priority: 
    -- 1st: Personal history (most frequent)
    -- 2nd: Platform popularity
    -- 3rd: Random active categories for discovery
    SELECT cat_id, priority FROM (
      SELECT category_id as cat_id, 1 as priority FROM user_history
      UNION
      SELECT category_id as cat_id, 2 as priority FROM popular_categories
      UNION
      SELECT id as cat_id, 3 as priority FROM public.categories WHERE is_active = true
    ) combined
    ORDER BY priority ASC, random()
    LIMIT 4
  )
  SELECT 
    c.id,
    c.name,
    c.description,
    c.icon,
    c.color,
    c.services,
    c.average_rate,
    c.total_providers,
    c.is_active
  FROM 
    public.categories c
  JOIN 
    recommended_ids r ON c.id = r.cat_id
  WHERE 
    c.is_active = true;
END;
$$;

-- EXPLICITLY grant permission to our app roles
GRANT EXECUTE ON FUNCTION public.get_user_recommendations(UUID) TO anon;
GRANT EXECUTE ON FUNCTION public.get_user_recommendations(UUID) TO authenticated;

