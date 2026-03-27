-- Migration: 029_demand_liquidity.sql
-- Goal: Provide geospatial demand data to balance the marketplace.

-- 1. Heatmap RPC: Returns clusters of demand (bookings + searches)
-- We use a simple grid-based clustering for performance.
CREATE OR REPLACE FUNCTION public.get_demand_heatmap(
    min_lat FLOAT, 
    max_lat FLOAT, 
    min_lng FLOAT, 
    max_lng FLOAT,
    precision_digits INT DEFAULT 3 -- Grid precision (3 is approx 100m)
)
RETURNS TABLE (
    lat FLOAT,
    lng FLOAT,
    intensity FLOAT, -- 0.0 to 1.0 scale
    demand_type TEXT -- 'booking' or 'search'
) AS $$
BEGIN
    RETURN QUERY
    -- Combine bookings and search events
    WITH raw_demand AS (
        -- Recent Bookings (last 7 days)
        SELECT 
            ROUND((service_location->>'latitude')::numeric, precision_digits)::float as p_lat,
            ROUND((service_location->>'longitude')::numeric, precision_digits)::float as p_lng,
            'booking' as type
        FROM public.bookings
        WHERE created_at > now() - interval '7 days'
          AND (service_location->>'latitude')::float BETWEEN min_lat AND max_lat
          AND (service_location->>'longitude')::float BETWEEN min_lng AND max_lng

        UNION ALL

        -- Recent Searches/Category Clicks (from events table)
        SELECT 
            ROUND((metadata->>'latitude')::numeric, precision_digits)::float as p_lat,
            ROUND((metadata->>'longitude')::numeric, precision_digits)::float as p_lng,
            'search' as type
        FROM public.events
        WHERE event_type IN ('category_click', 'search')
          AND created_at > now() - interval '24 hours'
          AND (metadata->>'latitude') IS NOT NULL
          AND (metadata->>'latitude')::float BETWEEN min_lat AND max_lat
          AND (metadata->>'longitude')::float BETWEEN min_lng AND max_lng
    ),
    clustered_demand AS (
        SELECT 
            p_lat, 
            p_lng, 
            type,
            COUNT(*) as count
        FROM raw_demand
        GROUP BY p_lat, p_lng, type
    ),
    max_vals AS (
        SELECT MAX(count) as max_count FROM clustered_demand
    )
    SELECT 
        p_lat,
        p_lng,
        (count::float / GREATEST(max_count, 1)::float) as intensity,
        type
    FROM clustered_demand, max_vals;
END;
$$ LANGUAGE plpgsql STABLE;

-- 2. Grant permissions
GRANT EXECUTE ON FUNCTION public.get_demand_heatmap TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_demand_heatmap TO anon;
