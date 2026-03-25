-- =============================================
-- Migration 005: Enhance Verified Reviews System
-- Run this in Supabase SQL Editor
-- =============================================

-- 1. Prevent duplicate reviews for the same booking
ALTER TABLE public.reviews 
ADD CONSTRAINT unique_booking_review UNIQUE (booking_id);

-- 2. Add Trigger to Auto-update Service Provider Rating & review count
CREATE OR REPLACE FUNCTION update_provider_rating()
RETURNS TRIGGER AS $$
DECLARE
  target_provider_id UUID;
BEGIN
  -- Handle DELETE appropriately
  IF TG_OP = 'DELETE' THEN
    target_provider_id := OLD.provider_id;
  ELSE
    target_provider_id := NEW.provider_id;
  END IF;

  -- Update the provider's profile with the new average rating and count
  UPDATE public.service_providers
  SET 
    rating = COALESCE((
      SELECT ROUND(AVG(rating)::numeric, 1) FROM public.reviews WHERE provider_id = target_provider_id
    ), 0),
    total_reviews = (
      SELECT COUNT(*) FROM public.reviews WHERE provider_id = target_provider_id
    )
  WHERE id = target_provider_id;
  
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_review_created_or_deleted ON public.reviews;
CREATE TRIGGER on_review_created_or_deleted
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW
EXECUTE FUNCTION update_provider_rating();

-- 3. Update RLS policy to ensure customers can only review COMPLETED bookings
DROP POLICY IF EXISTS "Customers can create reviews" ON public.reviews;

CREATE POLICY "Customers can create reviews" ON public.reviews
  FOR INSERT WITH CHECK (
    customer_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.bookings b 
      WHERE b.id = booking_id AND b.status = 'completed'
    )
  );

-- 4. Admins can delete reviews
DROP POLICY IF EXISTS "Admins can delete reviews" ON public.reviews;

CREATE POLICY "Admins can delete reviews" ON public.reviews
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );
