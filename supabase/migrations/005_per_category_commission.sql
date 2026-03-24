-- =============================================
-- Migration 005: Per-Category Commission Rates
-- Run this in Supabase SQL Editor
-- =============================================

-- 1. Add commission_rate column to categories table
--    Each category can have its own platform cut (%).
ALTER TABLE public.categories
  ADD COLUMN IF NOT EXISTS commission_rate NUMERIC(5,2) NOT NULL DEFAULT 10.0;

-- 2. Ensure the global setting still exists as a fallback
INSERT INTO public.platform_settings (key, value, label) VALUES
  ('commission_rate', '10', 'Global Default Commission Rate (%)')
ON CONFLICT (key) DO NOTHING;

-- 3. View that gives admin the earnings summary per category
CREATE OR REPLACE VIEW public.admin_earnings_by_category AS
SELECT
    c.id                                         AS category_id,
    c.name                                       AS category_name,
    c.icon                                       AS category_icon,
    c.color                                      AS category_color,
    c.commission_rate                            AS commission_rate,
    COUNT(b.id)                                  AS total_bookings,
    COALESCE(SUM((b.price->>'totalAmount')::NUMERIC), 0)  AS gross_revenue,
    COALESCE(SUM(
        (b.price->>'totalAmount')::NUMERIC * c.commission_rate / 100
    ), 0)                                        AS platform_profit,
    COALESCE(SUM(
        (b.price->>'totalAmount')::NUMERIC * (1 - c.commission_rate / 100)
    ), 0)                                        AS provider_payouts
FROM public.categories c
LEFT JOIN public.bookings b
    ON b.category_id = c.id AND b.status = 'completed'
GROUP BY c.id, c.name, c.icon, c.color, c.commission_rate
ORDER BY platform_profit DESC;

-- 4. RLS for the view (admins only)
--    Views inherit underlying table policies, but we create this for clarity.
GRANT SELECT ON public.admin_earnings_by_category TO authenticated;
