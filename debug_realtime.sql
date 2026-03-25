-- Diagnostic SQL to check Realtime and RLS status
-- Run this in the Supabase SQL Editor

-- 1. Check if the table is in the realtime publication
SELECT 
    pubname, 
    schemaname, 
    tablename 
FROM pg_publication_tables 
WHERE tablename = 'parking_spots';

-- 2. Check if RLS is enabled on the table
SELECT 
    relname as table_name, 
    relrowsecurity as rls_enabled 
FROM pg_class 
JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid 
WHERE relname = 'parking_spots' AND nspname = 'public';

-- 3. Check existing RLS policies
SELECT * FROM pg_policies WHERE tablename = 'parking_spots';

-- 4. EMERGENCY FIX (If RLS is blocking you and you want to test):
-- Allow anyone to read parking_spots (uncomment to run)
-- CREATE POLICY "Allow public read" ON public.parking_spots FOR SELECT USING (true);
-- ALTER TABLE public.parking_spots ENABLE ROW LEVEL SECURITY; -- ensure it's on
