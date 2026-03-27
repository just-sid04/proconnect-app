-- Migration: 019_provider_status.sql
-- Goal: Add real-time online status and activity tracking for providers.

-- 1. Add fields to service_providers
ALTER TABLE public.service_providers
ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ DEFAULT now();

-- 2. Create index for performance ranking
CREATE INDEX IF NOT EXISTS idx_providers_is_online_active 
ON public.service_providers(is_online, last_active_at DESC);

-- 3. Update RLS (if needed, though already handled by existing policies)
-- Most providers can already manage their own rows.

-- 4. Function to update last_active_at (to be called by sessions/app heartbeat)
CREATE OR REPLACE FUNCTION public.update_provider_activity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.service_providers
    SET last_active_at = now()
    WHERE user_id = auth.uid();
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON COLUMN public.service_providers.is_online IS 'Manual toggle for provider availability (Ready to work).';
COMMENT ON COLUMN public.service_providers.last_active_at IS 'Timestamp of the last time the provider interacted with the app.';
