-- ==============================================================================
-- BUOY ERP: GLOBAL FACTORY DATA SHARING & ACCESS SETUP
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql
-- ==============================================================================
-- This makes all factory operational data (Employees, Production Orders,
-- Process Logs, Attendance, Payroll, and Inventory Items) shared and accessible
-- by all registered users and staff in the factory.
-- ==============================================================================

-- 1. EMPLOYEES & ATTENDANCE & PAYROLL
ALTER TABLE IF EXISTS public.employees DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.salary_payments DISABLE ROW LEVEL SECURITY;

-- Permissive policies in case RLS is re-enabled
DROP POLICY IF EXISTS "Global factory access for employees" ON public.employees;
CREATE POLICY "Global factory access for employees" ON public.employees FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for attendance" ON public.attendance;
CREATE POLICY "Global factory access for attendance" ON public.attendance FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for salary_payments" ON public.salary_payments;
CREATE POLICY "Global factory access for salary_payments" ON public.salary_payments FOR ALL TO public USING (true) WITH CHECK (true);

-- 2. FACTORY PRODUCTION ORDERS & PROCESS LOGS
ALTER TABLE IF EXISTS public.production_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.production_logs DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Global factory access for production_orders" ON public.production_orders;
CREATE POLICY "Global factory access for production_orders" ON public.production_orders FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for production_logs" ON public.production_logs;
CREATE POLICY "Global factory access for production_logs" ON public.production_logs FOR ALL TO public USING (true) WITH CHECK (true);

-- 3. INVENTORY ITEMS & NOTIFICATIONS
ALTER TABLE IF EXISTS public.items DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Global factory access for items" ON public.items;
CREATE POLICY "Global factory access for items" ON public.items FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Global factory access for notifications" ON public.notifications;
CREATE POLICY "Global factory access for notifications" ON public.notifications FOR ALL TO public USING (true) WITH CHECK (true);

-- 4. VERIFY STATUS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('items', 'employees', 'attendance', 'salary_payments', 'production_orders', 'production_logs', 'notifications');

