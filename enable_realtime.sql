-- SQL to enable Realtime for the parking_spots table
-- Run this in the Supabase SQL Editor

-- 1. Enable Realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE parking_spots;

-- 2. Set replica identity to FULL to ensure all columns (like status) 
-- are included in the 'old' record of the real-time payload.
ALTER TABLE parking_spots REPLICA IDENTITY FULL;

-- 3. Verify that the table is in the publication
SELECT * FROM pg_publication_tables WHERE tablename = 'parking_spots';
