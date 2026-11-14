-- ==============================================================================
-- BUOY ERP: INVENTORY ITEMS RLS FIX
-- Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql
-- ==============================================================================

-- 1. Ensure items table exists with all required fields
CREATE TABLE IF NOT EXISTS public.items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT,
  subtitle TEXT,
  item_code TEXT,
  category TEXT,
  type TEXT,
  stock_quantity TEXT,
  min_quantity TEXT,
  metric TEXT,
  unit TEXT,
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Option A: Disable RLS completely on items (Recommended for ERP backend)
ALTER TABLE public.items DISABLE ROW LEVEL SECURITY;

-- 3. Option B: If you prefer RLS enabled, create permissive policies for both anon and authenticated roles:
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access on items" ON public.items;
CREATE POLICY "Allow public read access on items"
ON public.items FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Allow public insert access on items" ON public.items;
CREATE POLICY "Allow public insert access on items"
ON public.items FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update access on items" ON public.items;
CREATE POLICY "Allow public update access on items"
ON public.items FOR UPDATE
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public delete access on items" ON public.items;
CREATE POLICY "Allow public delete access on items"
ON public.items FOR DELETE
USING (true);

-- ==============================================================================
-- Also ensure storage bucket 'items' allows public uploads:
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('items', 'items', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Allow public uploads to items bucket" ON storage.objects;
CREATE POLICY "Allow public uploads to items bucket"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'items');

DROP POLICY IF EXISTS "Allow public read from items bucket" ON storage.objects;
CREATE POLICY "Allow public read from items bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'items');

