-- Migration: 021_payments_rls_fix.sql
-- Goal: Fix missing INSERT and UPDATE policies for simulated payments.

-- 1. Allow customers to insert their own payments
CREATE POLICY "Customers can insert own payments"
    ON public.payments FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- 2. Allow customers to update their own payments (status simulation)
CREATE POLICY "Customers can update own payments"
    ON public.payments FOR UPDATE
    USING (auth.uid() = customer_id);

-- 3. Allow providers to view payments (already exists for SELECT, but let's be explicit for updates if needed)
-- Providers generally shouldn't update payments, but they might need to see them.
-- The SELECT policy is already in 018_payments_schema.sql.

-- 4. Ensure bookings table allows customers to update the payment flags
-- This already exists in 001_initial_schema.sql as "Customers can update own bookings"
-- but some systems might be more restrictive. Let's verify or re-grant if necessary.
-- (Currently assuming the broad FOR UPDATE policy is sufficient).

GRANT ALL ON TABLE public.payments TO authenticated;
