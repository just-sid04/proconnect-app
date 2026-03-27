-- Migration: 028_analytics_engine.sql
-- Goal: Establish the foundation for the Analytics & Metrics Engine.

-- 1. Events Table (The Core Foundation)
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL, -- e.g., 'booking_created', 'app_open', 'profile_view'
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

-- Policies: 
-- Users can insert their own events (logged-in or anonymous)
-- Admins can view all events
CREATE POLICY "Users can insert their own events" ON public.events
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Admins can view all events" ON public.events
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- 2. Daily Metrics Table (Snapshots for fast dashboard loading)
CREATE TABLE IF NOT EXISTS public.daily_metrics (
    date DATE PRIMARY KEY,
    daily_active_users INTEGER DEFAULT 0,
    new_bookings INTEGER DEFAULT 0,
    completed_bookings INTEGER DEFAULT 0,
    revenue DECIMAL(12,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Aggregated Views for Provider Analytics

-- View: Provider Performance Stats
CREATE OR REPLACE VIEW public.provider_stats AS
SELECT 
    sp.id as provider_id,
    sp.user_id,
    COUNT(b.id) as total_bookings,
    SUM(CASE WHEN b.status = 'completed' THEN (b.price->>'totalAmount')::numeric ELSE 0 END) as total_earnings,
    AVG(r.rating) as avg_rating,
    COUNT(DISTINCT e.id) FILTER (WHERE e.event_type = 'profile_view') as profile_views
FROM public.service_providers sp
LEFT JOIN public.bookings b ON sp.id = b.provider_id
LEFT JOIN public.reviews r ON b.id = r.booking_id
LEFT JOIN public.events e ON e.event_type = 'profile_view' AND (e.metadata->>'provider_id')::uuid = sp.id
GROUP BY sp.id, sp.user_id;

-- View: Category Performance
CREATE OR REPLACE VIEW public.category_performance AS
SELECT 
    c.id as category_id,
    c.name as category_name,
    COUNT(DISTINCT e.id) FILTER (WHERE e.event_type = 'category_click') as search_count,
    COUNT(DISTINCT b.id) as booking_count,
    CASE 
        WHEN COUNT(DISTINCT e.id) FILTER (WHERE e.event_type = 'category_click') > 0 
        THEN (COUNT(DISTINCT b.id)::float / COUNT(DISTINCT e.id) FILTER (WHERE e.event_type = 'category_click')::float) * 100
        ELSE 0 
    END as conversion_rate
FROM public.categories c
LEFT JOIN public.bookings b ON c.id = b.category_id
LEFT JOIN public.events e ON e.event_type = 'category_click' AND (e.metadata->>'category_id')::uuid = c.id
GROUP BY c.id, c.name;

-- 4. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_user_id ON public.events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON public.events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created_at ON public.events(created_at);
