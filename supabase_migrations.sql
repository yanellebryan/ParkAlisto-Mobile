-- ============================================================
-- ParkAlisto — Supabase Migration Script
-- Run this entire file in the Supabase SQL Editor
-- ============================================================

-- ── 1. Add new columns to bookings table ──────────────────────
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS booking_code TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS checked_in BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMPTZ;

-- ── 2. Backfill booking_code for existing rows that don't have one ──
UPDATE bookings
SET booking_code = 'PRK-' || UPPER(SUBSTR(id::text, 1, 6))
WHERE booking_code IS NULL;

-- ── 3. Create user_push_tokens table ──────────────────────────
CREATE TABLE IF NOT EXISTS user_push_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  token       TEXT NOT NULL,
  platform    TEXT NOT NULL DEFAULT 'unknown', -- 'android' | 'ios'
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- Enable RLS
ALTER TABLE user_push_tokens ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own tokens
CREATE POLICY "Users manage own push tokens"
  ON user_push_tokens
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── 4. Enable pg_cron extension (if not already enabled) ──────
-- NOTE: You must enable the pg_cron extension via:
-- Supabase Studio → Database → Extensions → search "pg_cron" → Enable
-- Then run the cron job schedule below:

-- ── 5. Auto-expire bookings job (runs every minute) ───────────
-- This fixes the parking spot "stuck as occupied" bug.
-- It frees spots and marks bookings as completed when the time window has passed.
SELECT cron.schedule(
  'auto-expire-booking-spots',   -- unique job name
  '* * * * *',                   -- every minute
  $$
    -- Step 1: Free the parking spots whose booking window has ended
    UPDATE parking_spots
    SET status = 'available'
    WHERE id IN (
      SELECT spot_id FROM bookings
      WHERE status = 'active'
        AND arrival_time IS NOT NULL
        AND (arrival_time + (duration_hours || ' hours')::INTERVAL) <= NOW()
    );

    -- Step 2: Mark those bookings as completed
    UPDATE bookings
    SET status = 'completed'
    WHERE status = 'active'
      AND arrival_time IS NOT NULL
      AND (arrival_time + (duration_hours || ' hours')::INTERVAL) <= NOW();

    -- Step 3: Also free spots for active bookings where booking_date (not arrival_time)
    -- has passed by more than (duration_hours + 2 hours) as a safety net
    UPDATE parking_spots
    SET status = 'available'
    WHERE id IN (
      SELECT spot_id FROM bookings
      WHERE status = 'active'
        AND arrival_time IS NULL
        AND booking_date IS NOT NULL
        AND (booking_date + ((duration_hours + 2) || ' hours')::INTERVAL) <= NOW()
    );

    UPDATE bookings
    SET status = 'completed'
    WHERE status = 'active'
      AND arrival_time IS NULL
      AND booking_date IS NOT NULL
      AND (booking_date + ((duration_hours + 2) || ' hours')::INTERVAL) <= NOW();
  $$
);

-- ── 6. Verify the cron job was created ────────────────────────
-- Run this separately to check:
-- SELECT * FROM cron.job WHERE jobname = 'auto-expire-booking-spots';

-- ── 7. Index for performance on the expiry query ──────────────
CREATE INDEX IF NOT EXISTS idx_bookings_active_arrival
  ON bookings(status, arrival_time)
  WHERE status = 'active';

-- ── 8. RLS policy: allow admin to read push tokens (for notifications) ──
-- If you have an admin role or service_role, adjust accordingly.
-- For now, the Edge Function will use service_role key to bypass RLS.

-- ── 9. Add booking_code index for fast QR lookup ──────────────
CREATE UNIQUE INDEX IF NOT EXISTS idx_bookings_booking_code
  ON bookings(booking_code);

-- ── Done! ─────────────────────────────────────────────────────
-- Next steps:
-- 1. Enable pg_cron in Supabase Studio → Database → Extensions
-- 2. Deploy the Edge Function for push notifications (see /supabase/functions/)
-- 3. Run `flutter pub get` after updating pubspec.yaml
