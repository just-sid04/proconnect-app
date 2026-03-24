-- ProConnect Supabase Schema
-- Run this in Supabase SQL Editor to set up the database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- PROFILES (extends Supabase auth.users)
-- =============================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  email TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'provider', 'admin')),
  profile_photo TEXT DEFAULT '',
  location JSONB DEFAULT NULL,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to create profile on signup (email comes from auth.users)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, phone, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- CATEGORIES
-- =============================================
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  icon TEXT DEFAULT 'default',
  color TEXT DEFAULT '#2196F3',
  services JSONB DEFAULT '[]',
  average_rate NUMERIC DEFAULT 0,
  total_providers INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- SERVICE PROVIDERS
-- =============================================
CREATE TABLE IF NOT EXISTS public.service_providers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  skills TEXT[] DEFAULT '{}',
  experience INT DEFAULT 0,
  hourly_rate NUMERIC DEFAULT 0,
  description TEXT DEFAULT '',
  availability JSONB DEFAULT '{}',
  service_area INT DEFAULT 10,
  is_verified BOOLEAN DEFAULT false,
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
  rating NUMERIC DEFAULT 0,
  total_reviews INT DEFAULT 0,
  total_bookings INT DEFAULT 0,
  portfolio TEXT[] DEFAULT '{}',
  documents TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- =============================================
-- BOOKINGS
-- =============================================
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'in-progress', 'completed', 'cancelled')),
  description TEXT NOT NULL DEFAULT '',
  service_location JSONB NOT NULL DEFAULT '{}',
  scheduled_date TEXT NOT NULL,
  scheduled_time TEXT NOT NULL,
  estimated_duration INT DEFAULT 2,
  price JSONB NOT NULL DEFAULT '{"hourlyRate":0,"estimatedHours":0,"totalAmount":0,"materialsCost":0}',
  notes TEXT DEFAULT '',
  accepted_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- REVIEWS
-- =============================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read/update own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Categories: Public read
CREATE POLICY "Categories are viewable by everyone" ON public.categories
  FOR SELECT USING (true);

-- Admin can manage categories (we'll use a function to check role)
CREATE POLICY "Admins can manage categories" ON public.categories
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Service Providers: Public read for verified, providers manage own
CREATE POLICY "Service providers viewable by everyone" ON public.service_providers
  FOR SELECT USING (true);

CREATE POLICY "Providers can manage own profile" ON public.service_providers
  FOR ALL USING (
    user_id = auth.uid()
  );

-- Bookings: Customers and providers involved can access
CREATE POLICY "Users can view own bookings" ON public.bookings
  FOR SELECT USING (
    customer_id = auth.uid() OR
    provider_id IN (SELECT id FROM service_providers WHERE user_id = auth.uid())
  );

CREATE POLICY "Customers can create bookings" ON public.bookings
  FOR INSERT WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Providers can update their bookings" ON public.bookings
  FOR UPDATE USING (
    provider_id IN (SELECT id FROM service_providers WHERE user_id = auth.uid())
  );

CREATE POLICY "Customers can update own bookings" ON public.bookings
  FOR UPDATE USING (customer_id = auth.uid());

-- Reviews: Public read, customers can create for their bookings
CREATE POLICY "Reviews viewable by everyone" ON public.reviews
  FOR SELECT USING (true);

CREATE POLICY "Customers can create reviews" ON public.reviews
  FOR INSERT WITH CHECK (customer_id = auth.uid());

-- =============================================
-- INDEXES
-- =============================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_service_providers_user ON public.service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_service_providers_category ON public.service_providers(category_id);
CREATE INDEX IF NOT EXISTS idx_service_providers_verified ON public.service_providers(is_verified);
CREATE INDEX IF NOT EXISTS idx_bookings_customer ON public.bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_provider ON public.bookings(provider_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_reviews_provider ON public.reviews(provider_id);

-- =============================================
-- SEED DEFAULT CATEGORIES (optional)
-- =============================================
INSERT INTO public.categories (id, name, description, icon, color, services, average_rate, total_providers, is_active) VALUES
  ('11111111-1111-1111-1111-111111111101'::uuid, 'Electrical Repair', 'Professional electrical services', 'electrical', '#FFC107', '["Electrical Wiring","Circuit Repair","Lighting Installation"]'::jsonb, 65, 0, true),
  ('11111111-1111-1111-1111-111111111102'::uuid, 'Plumbing', 'Expert plumbing services', 'plumbing', '#2196F3', '["Pipe Repair","Drain Cleaning","Water Heater Installation"]'::jsonb, 75, 0, true),
  ('11111111-1111-1111-1111-111111111103'::uuid, 'Appliance Repair', 'Reliable appliance repair', 'appliance', '#4CAF50', '["Refrigerator Repair","Washing Machine Repair"]'::jsonb, 80, 0, true),
  ('11111111-1111-1111-1111-111111111104'::uuid, 'Computer Services', 'Technical support and repair', 'computer', '#9C27B0', '["Computer Repair","Virus Removal","Data Recovery"]'::jsonb, 55, 0, true),
  ('11111111-1111-1111-1111-111111111105'::uuid, 'Home Maintenance', 'Comprehensive home maintenance', 'maintenance', '#FF5722', '["House Cleaning","Painting","Carpentry"]'::jsonb, 45, 0, true)
ON CONFLICT DO NOTHING;
