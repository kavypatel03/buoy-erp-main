-- ============================================================
-- BUOY ERP — Items Table RLS Fix
-- Run this in your Supabase Dashboard → SQL Editor
-- ============================================================

-- OPTION A (Recommended for backend-managed tables):
-- Completely disable RLS since your Node.js backend handles auth
-- ============================================================
ALTER TABLE public.items DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- OPTION B: Keep RLS but allow authenticated users full access
-- Only use this if you DON'T run Option A
-- ============================================================
-- DROP POLICY IF EXISTS "items_select" ON public.items;
-- DROP POLICY IF EXISTS "items_insert" ON public.items;
-- DROP POLICY IF EXISTS "items_update" ON public.items;
-- DROP POLICY IF EXISTS "items_delete" ON public.items;
--
-- CREATE POLICY "items_select" ON public.items
--   FOR SELECT USING (auth.role() = 'authenticated');
--
-- CREATE POLICY "items_insert" ON public.items
--   FOR INSERT WITH CHECK (auth.role() = 'authenticated');
--
-- CREATE POLICY "items_update" ON public.items
--   FOR UPDATE USING (auth.role() = 'authenticated');
--
-- CREATE POLICY "items_delete" ON public.items
--   FOR DELETE USING (auth.role() = 'authenticated');
--
-- ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Verify the result
-- ============================================================
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'items';

