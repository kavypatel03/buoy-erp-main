-- Create employees table
CREATE TABLE IF NOT EXISTS public.employees (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id uuid REFERENCES auth.users(id) NOT NULL,
  name text NOT NULL,
  phone text,
  role text,
  address text,
  profile_pic_url text,
  hourly_salary numeric NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable Row Level Security (RLS) for employees
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own employees
CREATE POLICY "Users can manage their own employees" 
ON public.employees
FOR ALL
USING (auth.uid() = owner_id);

-- Create attendance table
CREATE TABLE IF NOT EXISTS public.attendance (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id uuid REFERENCES public.employees(id) ON DELETE CASCADE NOT NULL,
  clock_in timestamp with time zone NOT NULL,
  clock_out timestamp with time zone,
  hours_worked numeric,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable Row Level Security (RLS) for attendance
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Allow users to manage attendance for their employees
CREATE POLICY "Users can manage attendance for their employees" 
ON public.attendance
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.employees 
    WHERE employees.id = attendance.employee_id 
    AND employees.owner_id = auth.uid()
  )
);
