-- =============================================
-- STEP 3: PROVIDER AVAILABILITY & SCHEDULING
-- =============================================

-- Table for recurring weekly schedules
CREATE TABLE IF NOT EXISTS public.provider_schedules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 1=Monday...
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(provider_id, day_of_week)
);

-- Table for specific blocked slots (holidays, personal time off)
CREATE TABLE IF NOT EXISTS public.provider_blocked_slots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  reason TEXT DEFAULT 'Unavailable',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (end_at > start_at)
);

-- Function to check if a provider is available at a specific time
CREATE OR REPLACE FUNCTION public.check_provider_availability(
  p_provider_id UUID,
  p_start_at TIMESTAMPTZ,
  p_duration_hours INT
) RETURNS BOOLEAN AS $$
DECLARE
  v_end_at TIMESTAMPTZ;
  v_day_of_week INT;
  v_time_only TIME;
  v_is_working BOOLEAN;
  v_is_blocked BOOLEAN;
  v_is_booked BOOLEAN;
BEGIN
  v_end_at := p_start_at + (p_duration_hours || ' hours')::INTERVAL;
  v_day_of_week := EXTRACT(DOW FROM p_start_at);
  v_time_only := p_start_at::TIME;

  -- 1. Check if it's within working hours for that day
  SELECT EXISTS (
    SELECT 1 FROM public.provider_schedules
    WHERE provider_id = p_provider_id
      AND day_of_week = v_day_of_week
      AND is_active = true
      AND start_time <= v_time_only
      AND end_time >= (p_start_at + (p_duration_hours || ' hours')::INTERVAL)::TIME
  ) INTO v_is_working;

  IF NOT v_is_working THEN
    RETURN FALSE;
  END IF;

  -- 2. Check if it overlaps with any manually blocked slots
  SELECT EXISTS (
    SELECT 1 FROM public.provider_blocked_slots
    WHERE provider_id = p_provider_id
      AND (
        (start_at <= p_start_at AND end_at > p_start_at) OR
        (start_at < v_end_at AND end_at >= v_end_at) OR
        (start_at >= p_start_at AND end_at <= v_end_at)
      )
  ) INTO v_is_blocked;

  IF v_is_blocked THEN
    RETURN FALSE;
  END IF;

  -- 3. Check if it overlaps with existing bookings (accepted or in-progress)
  SELECT EXISTS (
    SELECT 1 FROM public.bookings
    WHERE provider_id = p_provider_id
      AND status IN ('accepted', 'in-progress')
      -- Convert scheduled_date and scheduled_time to TIMESTAMPTZ for comparison
      AND (
        (
          (scheduled_date || ' ' || scheduled_time)::TIMESTAMPTZ <= p_start_at 
          AND ((scheduled_date || ' ' || scheduled_time)::TIMESTAMPTZ + (estimated_duration || ' hours')::INTERVAL) > p_start_at
        ) OR
        (
          (scheduled_date || ' ' || scheduled_time)::TIMESTAMPTZ < v_end_at 
          AND ((scheduled_date || ' ' || scheduled_time)::TIMESTAMPTZ + (estimated_duration || ' hours')::INTERVAL) >= v_end_at
        )
      )
  ) INTO v_is_booked;

  IF v_is_booked THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to prevent double bookings during INSERT or UPDATE on bookings table
CREATE OR REPLACE FUNCTION public.prevent_booking_conflict()
RETURNS TRIGGER AS $$
BEGIN
  -- Only check for New or status changes to 'accepted'
  IF (TG_OP = 'INSERT') OR (NEW.status = 'accepted' AND OLD.status = 'pending') THEN
    IF NOT public.check_provider_availability(
      NEW.provider_id,
      (NEW.scheduled_date || ' ' || NEW.scheduled_time)::TIMESTAMPTZ,
      NEW.estimated_duration
    ) THEN
      RAISE EXCEPTION 'Provider is not available during the requested time slot.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_prevent_booking_conflict
  BEFORE INSERT OR UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.prevent_booking_conflict();

-- RLS POLICIES
ALTER TABLE public.provider_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_blocked_slots ENABLE ROW LEVEL SECURITY;

-- Schedules: Public read (to show available times), Providers manage own
CREATE POLICY "Schedules are viewable by everyone" ON public.provider_schedules
  FOR SELECT USING (true);

CREATE POLICY "Providers can manage own schedule" ON public.provider_schedules
  FOR ALL USING (
    provider_id IN (SELECT id FROM service_providers WHERE user_id = auth.uid())
  );

-- Blocked Slots: Public read (to show unavailable times), Providers manage own
CREATE POLICY "Blocked slots are viewable by everyone" ON public.provider_blocked_slots
  FOR SELECT USING (true);

CREATE POLICY "Providers can manage own blocked slots" ON public.provider_blocked_slots
  FOR ALL USING (
    provider_id IN (SELECT id FROM service_providers WHERE user_id = auth.uid())
  );

-- Helper to seed some default hours for existing providers (optional but helpful)
INSERT INTO public.provider_schedules (provider_id, day_of_week, start_time, end_time)
SELECT id, d.day, '09:00:00'::TIME, '18:00:00'::TIME
FROM public.service_providers, generate_series(1, 5) AS d(day)
ON CONFLICT DO NOTHING;
