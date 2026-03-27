-- Migration: 030_performance_optimization.sql
-- Goal: Ensure fast global search and database performance at scale.

-- 1. Enable pg_trgm for fuzzy/substring search if not enabled
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. GIN Indexes for fast search on Profiles (Name)
CREATE INDEX IF NOT EXISTS idx_profiles_name_trgm ON public.profiles USING gin (name gin_trgm_ops);

-- 3. GIN Indexes for fast search on Service Providers (Description)
CREATE INDEX IF NOT EXISTS idx_sp_description_trgm ON public.service_providers USING gin (description gin_trgm_ops);

-- 4. GIN Indexes for metadata search in Events (Future-proofing AI)
CREATE INDEX IF NOT EXISTS idx_events_metadata_gin ON public.events USING gin (metadata);

-- 5. Optimized Search RPC (Optional but recommended for complex filters)
CREATE OR REPLACE FUNCTION public.search_global(search_query TEXT)
RETURNS TABLE (
    id UUID,
    name TEXT,
    role TEXT,
    profile_photo TEXT,
    relevance FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id, 
        p.name, 
        p.role, 
        p.profile_photo,
        similarity(p.name, search_query) as relevance
    FROM public.profiles p
    WHERE p.name % search_query
    ORDER BY relevance DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql STABLE;

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION public.search_global TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_global TO anon;
