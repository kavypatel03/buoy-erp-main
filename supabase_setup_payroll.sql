-- ==============================================================================
-- BUOY ERP: PAYROLL & UPI MODULE SETUP
-- Run this script in your Supabase SQL Editor.
-- ==============================================================================

-- 1. Add UPI ID to employees
ALTER TABLE employees ADD COLUMN IF NOT EXISTS upi_id TEXT;

-- 2. Create Salary Payments Table
CREATE TABLE IF NOT EXISTS salary_payments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC NOT NULL,
  payment_method TEXT NOT NULL, -- 'UPI' or 'Cash'
  paid_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Row Level Security (RLS) for Salary Payments
ALTER TABLE salary_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own employee payments" 
ON salary_payments FOR ALL 
USING (
  employee_id IN (
    SELECT id FROM employees WHERE owner_id = auth.uid()
  )
);

-- ==============================================================================
-- DONE!
-- ==============================================================================
