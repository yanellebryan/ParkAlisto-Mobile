-- 1. Ensure floor column exists
ALTER TABLE parking_spots ADD COLUMN IF NOT EXISTS floor INTEGER DEFAULT 1;

-- 2. Clear existing USLS spots to re-seed correctly with unique A-L rows
DELETE FROM parking_spots WHERE location_id = '367f5042-16cf-400b-b70a-1f39dccb735e';

-- 3. Re-seed 72 spots with unique labels A1-L6 (12 rows total)
DO $$
DECLARE
    loc_id UUID := '367f5042-16cf-400b-b70a-1f39dccb735e';
    -- 12 unique rows for 3 floors (4 rows per floor)
    row_names TEXT[] := ARRAY['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
    row_idx INT;
    spot_num INT;
    f INT;
    idx_in_floor INT;
    abs_idx INT;
    label TEXT;
BEGIN
    FOR f IN 1..3 LOOP
        FOR idx_in_floor IN 0..23 LOOP
            -- Calculate absolute index (0..71)
            abs_idx := (f - 1) * 24 + idx_in_floor;
            
            -- Each row has 6 spots. So row_idx is abs_idx / 6.
            row_idx := (abs_idx / 6)::int;
            spot_num := (abs_idx % 6) + 1;
            label := row_names[row_idx + 1] || spot_num;
            
            INSERT INTO parking_spots (location_id, label, row_letter, spot_number, status, floor)
            VALUES (loc_id, label, row_names[row_idx + 1], spot_num, 'available', f);
        END LOOP;
    END LOOP;
END $$;
