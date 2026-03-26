-- Migration: Enhanced Review System & Verification Storage
-- Description: Adds image support to reviews and sets up storage buckets for reviews and verification documents.

-- 1. Add images and provider response to reviews
ALTER TABLE public.reviews 
ADD COLUMN IF NOT EXISTS images TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS provider_response TEXT DEFAULT '';

-- 2. Create Storage Buckets
-- Reviews bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('reviews', 'reviews', true)
ON CONFLICT (id) DO NOTHING;

-- Verification documents bucket (PRIVATE)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('verifications', 'verifications', false)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage RLS Policies

-- Public access to review images
CREATE POLICY "Public Access to Reviews"
ON storage.objects FOR SELECT
USING (bucket_id = 'reviews');

-- Users can upload to reviews bucket if they have a completed booking
CREATE POLICY "Users can upload review images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'reviews' AND 
  auth.role() = 'authenticated'
);

-- Providers can upload their own verification documents
CREATE POLICY "Providers can upload verification docs"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'verifications' AND 
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Access to verification docs restricted to owner and admins
CREATE POLICY "Verification docs access"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'verifications' AND (
    auth.uid()::text = (storage.foldername(name))[1] OR
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  )
);
