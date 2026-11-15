-- ==============================================================================
-- BUOY ERP: GLOBAL FACTORY DATA SHARING, SCHEMA & NEGATIVE STOCK FIX (ALL-IN-ONE)
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql
-- ==============================================================================

-- ─── STEP 1: ENSURE ALL REQUIRED TABLES EXIST FIRST ──────────────────────────
CREATE TABLE IF NOT EXISTS public.items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT,
  subtitle TEXT,
  item_code TEXT,
  category TEXT,
  type TEXT,
  stock_quantity TEXT DEFAULT '0',
  min_quantity TEXT DEFAULT '0',
  metric TEXT DEFAULT '0',
  unit TEXT DEFAULT 'Kg',
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.employees (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  phone TEXT,
  role TEXT,
  address TEXT,
  profile_pic_url TEXT,
  upi_id TEXT,
  hourly_salary NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  clock_in TIMESTAMP WITH TIME ZONE NOT NULL,
  clock_out TIMESTAMP WITH TIME ZONE,
  hours_worked NUMERIC,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.salary_payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC NOT NULL,
  payment_method TEXT DEFAULT 'Cash',
  paid_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.production_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id),
  product_name TEXT NOT NULL,
  product_id TEXT,
  batch_code TEXT,
  status TEXT DEFAULT 'In Progress',
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.production_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id),
  order_id UUID REFERENCES public.production_orders(id) ON DELETE CASCADE NOT NULL,
  process_name TEXT NOT NULL,
  input_item_id UUID REFERENCES public.items(id),
  input_qty NUMERIC DEFAULT 0,
  output_qty NUMERIC DEFAULT 0,
  wastage_qty NUMERIC GENERATED ALWAYS AS (input_qty - output_qty) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.production_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  category TEXT DEFAULT 'Stationery',
  description TEXT,
  color TEXT DEFAULT '#8D6E63',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.app_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure production schema columns exist if table was created previously
ALTER TABLE public.production_orders ADD COLUMN IF NOT EXISTS product_id TEXT;
ALTER TABLE public.production_orders ADD COLUMN IF NOT EXISTS batch_code TEXT;

-- ─── STEP 2: FIX INVENTORY NEGATIVE STOCK & PREVENT MINUS VALUES ─────────────
-- Reset any items that currently have negative stock to 0
UPDATE public.items
SET stock_quantity = '0', metric = '0'
WHERE COALESCE(NULLIF(stock_quantity, '')::numeric, 0) < 0;

-- Safe trigger: clamps deduction to 0 so stock can NEVER become negative
CREATE OR REPLACE FUNCTION deduct_inventory_for_production()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.input_item_id IS NOT NULL AND NEW.input_qty > 0 THEN
    UPDATE public.items
    SET stock_quantity = GREATEST(0, (COALESCE(NULLIF(stock_quantity, '')::numeric, 0) - NEW.input_qty))::text,
        metric = GREATEST(0, (COALESCE(NULLIF(stock_quantity, '')::numeric, 0) - NEW.input_qty))::text
    WHERE id = NEW.input_item_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_deduct_inventory_for_production ON public.production_logs;
CREATE TRIGGER trg_deduct_inventory_for_production
AFTER INSERT ON public.production_logs
FOR EACH ROW
EXECUTE FUNCTION deduct_inventory_for_production();

-- ─── STEP 3: DISABLE RLS ACROSS ALL GLOBAL FACTORY TABLES ────────────────────
ALTER TABLE public.employees DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.salary_payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.production_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.production_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.production_products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.production_process_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings DISABLE ROW LEVEL SECURITY;

-- ─── STEP 4: PERMISSIVE GLOBAL ACCESS POLICIES (If RLS is ever re-enabled) ───
DROP POLICY IF EXISTS "Global factory access for employees" ON public.employees;
CREATE POLICY "Global factory access for employees" ON public.employees FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for attendance" ON public.attendance;
CREATE POLICY "Global factory access for attendance" ON public.attendance FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for salary_payments" ON public.salary_payments;
CREATE POLICY "Global factory access for salary_payments" ON public.salary_payments FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for production_orders" ON public.production_orders;
CREATE POLICY "Global factory access for production_orders" ON public.production_orders FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for production_logs" ON public.production_logs;
CREATE POLICY "Global factory access for production_logs" ON public.production_logs FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for items" ON public.items;
CREATE POLICY "Global factory access for items" ON public.items FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for notifications" ON public.notifications;
CREATE POLICY "Global factory access for notifications" ON public.notifications FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for production_products" ON public.production_products;
CREATE POLICY "Global factory access for production_products" ON public.production_products FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for production_process_templates" ON public.production_process_templates;
CREATE POLICY "Global factory access for production_process_templates" ON public.production_process_templates FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for app_settings" ON public.app_settings;
CREATE POLICY "Global factory access for app_settings" ON public.app_settings FOR ALL TO public USING (true) WITH CHECK (true);

-- ─── STEP 5: SEED DEFAULT PRODUCTION RECIPES (If not yet present) ────────────
INSERT INTO public.production_products (name, category, description, color)
VALUES
  ('Brown Pencil', 'Pencils', 'Standard graphite paper-rolled brown pencil', '#8D6E63'),
  ('White Pencil', 'Pencils', 'Premium polymer-coated white pencil', '#64748B'),
  ('Eraser (Red)', 'Erasers', 'Soft vinyl non-dust eraser in vibrant red', '#EF4444'),
  ('Eraser (Blue)', 'Erasers', 'Precision drafting non-smudge eraser in blue', '#3B82F6')
ON CONFLICT (name) DO NOTHING;

-- Seed Pre-defined Process Steps for Brown Pencil
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

-- Seed Pre-defined Process Steps for White Pencil
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

-- Seed Pre-defined Process Steps for Eraser (Red)
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

-- Seed Pre-defined Process Steps for Eraser (Blue)
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

-- ─── STEP 6: VERIFY STATUS ───────────────────────────────────────────────────
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN (
  'items', 
  'employees', 
  'attendance', 
  'salary_payments', 
  'production_orders', 
  'production_logs', 
  'notifications',
  'production_products',
  'production_process_templates',
  'app_settings'
);
