-- =============================================
-- STEP 4: IMAGE UPLOAD & STORAGE POLICIES
-- =============================================

-- 1. Ensure the 'avatars' bucket exists (Manual step in Dashboard is safer, but this is for reference)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;

-- 2. Enable RLS for the objects table (usually enabled by default)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Public Read Access
-- Allow anyone to see profile photos
CREATE POLICY "Avatar photos are publicly accessible" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- 4. Policy: Authenticated Insert
-- Allow users to upload to their own folder within the 'avatars' bucket
-- Using the pattern 'avatars/user_id/filename'
CREATE POLICY "Users can upload their own avatar" ON storage.objects
  FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- 5. Policy: Owner Update/Delete
-- Allow users to replace or delete their own uploads
CREATE POLICY "Users can update their own avatar" ON storage.objects
  FOR UPDATE USING (
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatar" ON storage.objects
  FOR DELETE USING (
    auth.uid()::text = (storage.foldername(name))[1]
  );
