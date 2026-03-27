-- Phase 2.3: Referral & Wallet System

-- 1. Add wallet and referral fields to profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS pro_credits DECIMAL(12,2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES auth.users(id);

-- 2. Create wallet_transactions table
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('credit', 'debit')),
    source TEXT NOT NULL CHECK (source IN ('referral', 'booking_payment', 'refund', 'bonus', 'admin')),
    description TEXT,
    reference_id UUID, -- booking_id or other reference
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on wallet_transactions
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own transactions"
ON public.wallet_transactions FOR SELECT
USING (auth.uid() = user_id);

-- 3. Function to generate unique referral code
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    done BOOLEAN := FALSE;
BEGIN
    WHILE NOT done LOOP
        new_code := upper(substring(md5(random()::text) from 1 for 8));
        -- Check if code exists
        IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE referral_code = new_code) THEN
            done := TRUE;
        END IF;
    END LOOP;
    RETURN new_code;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger to assign referral code on profile creation
CREATE OR REPLACE FUNCTION public.handle_new_profile_referral()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.referral_code IS NULL THEN
        NEW.referral_code := generate_referral_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_profile_referral_created
    BEFORE INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_profile_referral();

-- 5. Logic for referral rewards (Example: 50 credits to both)
CREATE OR REPLACE FUNCTION public.process_referral_reward(referred_user_id UUID, code TEXT)
RETURNS VOID AS $$
DECLARE
    referrer_id UUID;
BEGIN
    -- Find referrer
    SELECT id INTO referrer_id FROM public.profiles WHERE referral_code = code;
    
    IF referrer_id IS NOT NULL AND referrer_id != referred_user_id THEN
        -- Update referred user
        UPDATE public.profiles SET referred_by = referrer_id WHERE id = referred_user_id;
        
        -- Credit referrer
        INSERT INTO public.wallet_transactions (user_id, amount, type, source, description)
        VALUES (referrer_id, 50.00, 'credit', 'referral', 'Referral bonus for inviting a friend');
        
        UPDATE public.profiles SET pro_credits = pro_credits + 50.00 WHERE id = referrer_id;
        
        -- Credit referred user
        INSERT INTO public.wallet_transactions (user_id, amount, type, source, description)
        VALUES (referred_user_id, 25.00, 'credit', 'referral', 'Welcome bonus using referral code');
        
        UPDATE public.profiles SET pro_credits = pro_credits + 25.00 WHERE id = referred_user_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
