-- 1. Add floor column to parking_spots if it doesn't exist
ALTER TABLE parking_spots ADD COLUMN IF NOT EXISTS floor INTEGER DEFAULT 1;

-- 2. Clear existing USLS spots to re-seed correctly
DELETE FROM parking_spots WHERE location_id = '367f5042-16cf-400b-b70a-1f39dccb735e';

-- 3. Re-seed 72 spots with correct floor division (24 per floor)
DO $$
DECLARE
    loc_id UUID := '367f5042-16cf-400b-b70a-1f39dccb735e';
    row_names TEXT[] := ARRAY['A', 'B', 'C', 'D', 'E', 'F'];
    row_idx INT;
    spot_num INT;
    f INT;
    i INT;
    idx_in_floor INT;
    label TEXT;
BEGIN
    FOR f IN 1..3 LOOP
        FOR idx_in_floor IN 0..23 LOOP
            -- Calculate absolute index (0..71)
            i := (f - 1) * 24 + idx_in_floor;
            
            -- Correct row mapping: Floor 1 (A-D), Floor 2 (E-F, A-B), Floor 3 (C-F)
            -- But for simplicity and matching the mobile app's loop:
            row_idx := (i / 6)::int % 6;
            spot_num := (i % 6) + 1;
            label := row_names[row_idx + 1] || spot_num;
            
            INSERT INTO parking_spots (location_id, label, row_letter, spot_number, status, floor)
            VALUES (loc_id, label, row_names[row_idx + 1], spot_num, 'available', f);
        END LOOP;
    END LOOP;
END $$;
