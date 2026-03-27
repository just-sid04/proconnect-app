-- Migration: 018_payments_schema.sql
-- Goal: Create a production-ready payments table to support the simulated and future real Razorpay workflow.

-- 1. Create Payment Status Enum if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE public.payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');
    END IF;
END $$;

-- 2. Create Payment Type Enum if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_type') THEN
        CREATE TYPE public.payment_type AS ENUM ('advance_20', 'final_80', 'full');
    END IF;
END $$;

-- 3. Create Payments Table
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.profiles(id),
    provider_id UUID NOT NULL REFERENCES public.profiles(id),
    amount DECIMAL(10, 2) NOT NULL,
    currency TEXT DEFAULT 'INR',
    status public.payment_status DEFAULT 'pending',
    payment_type public.payment_type NOT NULL,
    transaction_id TEXT, -- Razorpay Order ID or Mock ID
    payment_id TEXT,      -- Razorpay Payment ID or Mock ID
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Enable RLS
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Customers can see their own payments
CREATE POLICY "Customers can view their own payments"
    ON public.payments FOR SELECT
    USING (auth.uid() = customer_id);

-- Providers can see payments for bookings assigned to them
CREATE POLICY "Providers can view payments they received"
    ON public.payments FOR SELECT
    USING (auth.uid() = provider_id);

-- System/Service Role can manage all
CREATE POLICY "Admins can manage all payments"
    ON public.payments FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
    ));

-- 6. Add "paid" flags to bookings table (optional but helpful for quick UI checks)
ALTER TABLE public.bookings 
ADD COLUMN IF NOT EXISTS advance_paid BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS final_paid BOOLEAN DEFAULT false;

-- 7. Grant access
GRANT ALL ON TABLE public.payments TO authenticated;
GRANT ALL ON TABLE public.payments TO service_role;
GRANT SELECT ON TABLE public.payments TO anon; -- For public status checks if needed

-- 8. Add updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_payments_updated_at
    BEFORE UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

COMMENT ON TABLE public.payments IS 'Tracks all financial transactions for bookings (Simulated & Real).';
