-- ==============================================================================
-- BUOY ERP: PRODUCTION RECIPES & PRODUCT PROCESS TEMPLATES SETUP
-- ==============================================================================
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql
-- ==============================================================================

-- 1. Create table for Product Types
CREATE TABLE IF NOT EXISTS public.production_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  category TEXT DEFAULT 'Stationery',
  description TEXT,
  color TEXT DEFAULT '#8D6E63',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create table for Pre-defined Process Steps under each Product
CREATE TABLE IF NOT EXISTS public.production_process_templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES public.production_products(id) ON DELETE CASCADE NOT NULL,
  step_number INT NOT NULL,
  process_name TEXT NOT NULL,
  expected_tolerance_pct NUMERIC DEFAULT 5.0,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(product_id, step_number)
);

-- 3. Disable RLS for global factory access
ALTER TABLE IF EXISTS public.production_products DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.production_process_templates DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Global access for production_products" ON public.production_products;
CREATE POLICY "Global access for production_products" ON public.production_products FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global access for production_process_templates" ON public.production_process_templates;
CREATE POLICY "Global access for production_process_templates" ON public.production_process_templates FOR ALL TO public USING (true) WITH CHECK (true);

-- 4. Insert Default Starter Factory Products
INSERT INTO public.production_products (name, category, description, color)
VALUES
  ('Brown Pencil', 'Pencils', 'Standard graphite paper-rolled brown pencil', '#8D6E63'),
  ('White Pencil', 'Pencils', 'Premium polymer-coated white pencil', '#64748B'),
  ('Eraser (Red)', 'Erasers', 'Soft vinyl non-dust eraser in vibrant red', '#EF4444'),
  ('Eraser (Blue)', 'Erasers', 'Precision drafting non-smudge eraser in blue', '#3B82F6')
ON CONFLICT (name) DO NOTHING;

-- 5. Seed Pre-defined Process Steps for Brown Pencil
WITH p AS (SELECT id FROM public.production_products WHERE name = 'Brown Pencil' LIMIT 1)
INSERT INTO public.production_process_templates (product_id, step_number, process_name, expected_tolerance_pct)
SELECT p.id, s.step, s.name, s.tol
FROM p, (VALUES
  (1, 'Paper Cutting', 3.0),
  (2, 'Rolling & Glueing', 4.0),
  (3, 'Drying', 2.0),
  (4, 'Lead Insertion', 3.0),
  (5, 'Polishing & Shaping', 5.0),
  (6, 'Final Packaging', 1.0)
) AS s(step, name, tol)
ON CONFLICT (product_id, step_number) DO UPDATE
SET process_name = EXCLUDED.process_name, expected_tolerance_pct = EXCLUDED.expected_tolerance_pct;

-- 6. Seed Pre-defined Process Steps for White Pencil
WITH p AS (SELECT id FROM public.production_products WHERE name = 'White Pencil' LIMIT 1)
INSERT INTO public.production_process_templates (product_id, step_number, process_name, expected_tolerance_pct)
SELECT p.id, s.step, s.name, s.tol
FROM p, (VALUES
  (1, 'Paper Cutting', 3.0),
  (2, 'Rolling', 4.0),
  (3, 'Bleaching & Coating', 4.0),
  (4, 'Drying', 2.0),
  (5, 'Polishing', 5.0),
  (6, 'Packaging', 1.0)
) AS s(step, name, tol)
ON CONFLICT (product_id, step_number) DO UPDATE
SET process_name = EXCLUDED.process_name, expected_tolerance_pct = EXCLUDED.expected_tolerance_pct;

-- 7. Seed Pre-defined Process Steps for Eraser (Red)
WITH p AS (SELECT id FROM public.production_products WHERE name = 'Eraser (Red)' LIMIT 1)
INSERT INTO public.production_process_templates (product_id, step_number, process_name, expected_tolerance_pct)
SELECT p.id, s.step, s.name, s.tol
FROM p, (VALUES
  (1, 'Rubber Compounding', 4.0),
  (2, 'Dye Mixing (Red)', 2.0),
  (3, 'Extrusion & Molding', 5.0),
  (4, 'Cooling & Slicing', 3.0),
  (5, 'Quality Inspection & Packing', 2.0)
) AS s(step, name, tol)
ON CONFLICT (product_id, step_number) DO UPDATE
SET process_name = EXCLUDED.process_name, expected_tolerance_pct = EXCLUDED.expected_tolerance_pct;

-- 8. Seed Pre-defined Process Steps for Eraser (Blue)
WITH p AS (SELECT id FROM public.production_products WHERE name = 'Eraser (Blue)' LIMIT 1)
INSERT INTO public.production_process_templates (product_id, step_number, process_name, expected_tolerance_pct)
SELECT p.id, s.step, s.name, s.tol
FROM p, (VALUES
  (1, 'Rubber Compounding', 4.0),
  (2, 'Dye Mixing (Blue)', 2.0),
  (3, 'Extrusion & Molding', 5.0),
  (4, 'Cooling & Slicing', 3.0),
  (5, 'Quality Inspection & Packing', 2.0)
) AS s(step, name, tol)
ON CONFLICT (product_id, step_number) DO UPDATE
SET process_name = EXCLUDED.process_name, expected_tolerance_pct = EXCLUDED.expected_tolerance_pct;

-- 9. Check results
SELECT p.name AS product, t.step_number, t.process_name, t.expected_tolerance_pct
FROM public.production_products p
JOIN public.production_process_templates t ON p.id = t.product_id
ORDER BY p.name, t.step_number;

