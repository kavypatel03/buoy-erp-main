-- ==============================================================================
-- BUOY ERP: PRODUCTION & MANUFACTURING MODULE SETUP
-- Run this script in your Supabase SQL Editor.
-- ==============================================================================

-- 1. Create Production Orders Table
CREATE TABLE IF NOT EXISTS production_orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  product_name TEXT NOT NULL,
  status TEXT DEFAULT 'In Progress', -- In Progress, Completed, Paused
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create Production Process Logs Table (Tracks input/output and wastage)
CREATE TABLE IF NOT EXISTS production_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) NOT NULL,
  order_id UUID REFERENCES production_orders(id) ON DELETE CASCADE NOT NULL,
  process_name TEXT NOT NULL, -- e.g., 'Paper Cutting', 'Lead Insertion'
  input_item_id UUID REFERENCES items(id), -- The raw material used from inventory
  input_qty NUMERIC DEFAULT 0,
  output_qty NUMERIC DEFAULT 0,
  wastage_qty NUMERIC GENERATED ALWAYS AS (input_qty - output_qty) STORED,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Row Level Security (RLS) for Production Tables
ALTER TABLE production_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_logs ENABLE ROW LEVEL SECURITY;

-- Production Orders Policies
DROP POLICY IF EXISTS "Users can manage their own production orders" ON production_orders;
CREATE POLICY "Users can manage their own production orders" 
ON production_orders FOR ALL 
USING (auth.uid() = owner_id);

-- Production Logs Policies
DROP POLICY IF EXISTS "Users can manage their own production logs" ON production_logs;
CREATE POLICY "Users can manage their own production logs" 
ON production_logs FOR ALL 
USING (auth.uid() = owner_id);

-- 4. Automated Inventory Deduction Trigger
-- When a production log is added, automatically deduct the input_qty from inventory items.
CREATE OR REPLACE FUNCTION deduct_inventory_for_production()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.input_item_id IS NOT NULL AND NEW.input_qty > 0 THEN
    UPDATE items
    SET stock_quantity = stock_quantity - NEW.input_qty
    WHERE id = NEW.input_item_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_deduct_inventory_for_production ON production_logs;
CREATE TRIGGER trg_deduct_inventory_for_production
AFTER INSERT ON production_logs
FOR EACH ROW
EXECUTE FUNCTION deduct_inventory_for_production();

-- ==============================================================================
-- DONE!
-- ==============================================================================
