-- =============================================
-- Migration 004: Platform Settings Table
-- Run this in Supabase SQL Editor
-- =============================================

-- Create platform_settings table for admin-configurable values
CREATE TABLE IF NOT EXISTS public.platform_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  label TEXT DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read settings (needed to show commission rate to providers)
CREATE POLICY "Authenticated users can read settings"
  ON public.platform_settings
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only admins can update settings
CREATE POLICY "Admins can manage settings"
  ON public.platform_settings
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Seed default values
INSERT INTO public.platform_settings (key, value, label) VALUES
  ('commission_rate', '10', 'Platform Commission Rate (%)'),
  ('platform_name', 'ProConnect', 'Platform Name'),
  ('support_email', 'support@proconnect.com', 'Support Email')
ON CONFLICT (key) DO NOTHING;
