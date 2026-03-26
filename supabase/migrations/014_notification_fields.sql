-- Migration: Add FCM Token field for Push Notifications
-- Description: Adds fcm_token to profiles to allow Supabase to trigger notifications.

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add index for token lookups if needed (though mostly by user_id)
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON public.profiles (fcm_token);
