-- Seed Script for Phase 3 Testing (Trigger Fix)
-- This inserts mock events and bookings. We disable triggers temporarily to bypass availability checks.

-- 1. Insert Mock Events for Heatmap (Last 24 hours)
INSERT INTO public.events (user_id, event_type, metadata, created_at)
SELECT 
    (SELECT id FROM auth.users LIMIT 1),
    'category_click',
    jsonb_build_object(
        'category_id', '11111111-1111-1111-1111-111111111101',
        'latitude', 19.07 + (random() * 0.05) - 0.025,
        'longitude', 72.87 + (random() * 0.05) - 0.025
    ),
    now() - (random() * interval '24 hours')
FROM generate_series(1, 40);

-- 2. Insert Mock Bookings
-- We DISABLE only USER triggers to avoid "Provider is not available" error while keeping system constraints
ALTER TABLE public.bookings DISABLE TRIGGER USER;

INSERT INTO public.bookings (
    customer_id, 
    provider_id, 
    category_id, 
    status, 
    description, 
    service_location, 
    scheduled_date, 
    scheduled_time, 
    price
)
SELECT 
    (SELECT id FROM public.profiles WHERE role = 'customer' LIMIT 1),
    (SELECT id FROM public.service_providers LIMIT 1),
    (SELECT id FROM public.categories LIMIT 1),
    'completed',
    'Mock booking for analytics',
    jsonb_build_object(
        'latitude', 19.07 + (random() * 0.05) - 0.025,
        'longitude', 72.87 + (random() * 0.05) - 0.025,
        'address', 'Test Address ' || i
    ),
    to_char(now() - (i * interval '1 day'), 'YYYY-MM-DD'),
    '10:00',
    jsonb_build_object(
        'hourlyRate', 500,
        'estimatedHours', 2,
        'totalAmount', 1000,
        'materialsCost', 0
    )
FROM generate_series(1, 15) as i
WHERE EXISTS (SELECT 1 FROM public.service_providers LIMIT 1);

ALTER TABLE public.bookings ENABLE TRIGGER USER;

-- 3. Insert Mock Profile Views
INSERT INTO public.events (user_id, event_type, metadata, created_at)
SELECT 
    (SELECT id FROM auth.users LIMIT 1),
    'profile_view',
    jsonb_build_object(
        'provider_id', (SELECT id FROM public.service_providers LIMIT 1)
    ),
    now() - (random() * interval '7 days')
FROM generate_series(1, 60)
WHERE EXISTS (SELECT 1 FROM public.service_providers LIMIT 1);
