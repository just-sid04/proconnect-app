-- Migration 032: Fix User Creation Trigger
-- Goal: Harden the handle_new_user function to handle missing/empty metadata from the Supabase Dashboard.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- We use NULLIF to handle empty strings ('') and safe casting for numeric/uuid fields.
  -- This prevents "invalid input syntax" errors when creating users from the dashboard.
  INSERT INTO public.profiles (
    id, 
    name, 
    email, 
    phone, 
    role, 
    latitude, 
    longitude, 
    service_radius, 
    location,
    is_active,
    is_verified,
    profile_photo
  )
  VALUES (
    NEW.id,
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'name', ''), 'User'),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NULLIF(NEW.raw_user_meta_data->>'role', ''), 'customer'),
    (NULLIF(NEW.raw_user_meta_data->>'latitude', ''))::DOUBLE PRECISION,
    (NULLIF(NEW.raw_user_meta_data->>'longitude', ''))::DOUBLE PRECISION,
    COALESCE((NULLIF(NEW.raw_user_meta_data->>'service_radius', ''))::DOUBLE PRECISION, 20.0),
    CASE 
      WHEN jsonb_typeof(NEW.raw_user_meta_data->'location') = 'object' THEN NEW.raw_user_meta_data->'location'
      ELSE NULL
    END,
    true,   -- is_active default
    false,  -- is_verified default
    ''      -- profile_photo default
  );

  -- If provider, create record in service_providers
  IF (NEW.raw_user_meta_data->>'role' = 'provider') THEN
    INSERT INTO public.service_providers (
      user_id, 
      category_id, 
      hourly_rate, 
      description, 
      is_verified
    ) VALUES (
      NEW.id,
      COALESCE(
        (NULLIF(NEW.raw_user_meta_data->>'categoryId', ''))::UUID, 
        '11111111-1111-1111-1111-111111111105'::UUID -- Default Home Maintenance
      ),
      COALESCE((NULLIF(NEW.raw_user_meta_data->>'hourlyRate', ''))::NUMERIC, 0),
      COALESCE(NEW.raw_user_meta_data->>'description', 'Professional Service Provider'),
      false
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
