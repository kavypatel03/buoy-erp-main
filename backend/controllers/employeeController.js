const supabase = require('../config/supabase');
const { createClient } = require('@supabase/supabase-js');

// Create admin client bypassing RLS using SERVICE_ROLE_KEY
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// Get all employees for the current user
exports.getEmployees = async (req, res) => {
  try {
    const userId = req.user.id;

    // Fetch employees, their attendance, and their salary_payments in a single optimized query
    const { data: employees, error: empError } = await supabaseAdmin
      .from('employees')
      .select('*, attendance(*), salary_payments(*)')
      .eq('owner_id', userId)
      .order('created_at', { ascending: false });

    if (empError) throw empError;

    const employeesWithStats = employees.map(emp => {
      const empAttendance = emp.attendance || [];
      const empPayments = emp.salary_payments || [];
      
      let totalHours = 0;
      empAttendance.forEach(record => {
        if (record.clock_in && record.clock_out) {
          const diffMs = new Date(record.clock_out) - new Date(record.clock_in);
          const diffHrs = diffMs / (1000 * 60 * 60);
          totalHours += diffHrs;
        }
      });

      const totalSalary = totalHours * emp.hourly_salary;
      const totalPaid = empPayments.reduce((sum, p) => sum + Number(p.amount), 0);
      const payableSalary = totalSalary - totalPaid;

      return {
        ...emp,
        total_hours: totalHours.toFixed(2),
        total_salary: totalSalary.toFixed(2),
        total_paid: totalPaid.toFixed(2),
        payable_salary: (payableSalary > 0 ? payableSalary : 0).toFixed(2),
        is_clocked_in: empAttendance.some(a => !a.clock_out),
        salary_payments: empPayments.sort((a, b) => new Date(b.paid_at) - new Date(a.paid_at)) // Sort history newest first
      };
    });

    res.status(200).json(employeesWithStats);
  } catch (error) {
    console.error('Error fetching employees:', error);
    res.status(500).json({ error: error.message });
  }
};

// Create a new employee
exports.createEmployee = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, hourly_salary, profile_pic_url, phone, role, address, upi_id } = req.body;

    if (!name || !hourly_salary) {
      return res.status(400).json({ error: 'Name and hourly salary are required' });
    }

    const { data, error } = await supabaseAdmin
      .from('employees')
      .insert([{
        owner_id: userId,
        name,
        hourly_salary,
        profile_pic_url,
        phone,
        role,
        address,
        upi_id
      }])
      .select();

    if (error) throw error;

    res.status(201).json(data[0]);
  } catch (error) {
    console.error('Error creating employee:', error);
    res.status(500).json({ error: error.message });
  }
};

// Edit an existing employee
exports.editEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, hourly_salary, profile_pic_url, phone, role, address, upi_id } = req.body;

    const { data, error } = await supabaseAdmin
      .from('employees')
      .update({
        name,
        hourly_salary,
        profile_pic_url,
        phone,
        role,
        address,
        upi_id
      })
      .eq('id', id)
      .select();

    if (error) throw error;
    res.status(200).json(data[0]);
  } catch (error) {
    console.error('Error editing employee:', error);
    res.status(500).json({ error: error.message });
  }
};

// Pay Salary
exports.paySalary = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, payment_method } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid amount is required' });
    }
    if (!['UPI', 'Cash'].includes(payment_method)) {
      return res.status(400).json({ error: 'Invalid payment method' });
    }

    const { data, error } = await supabaseAdmin
      .from('salary_payments')
      .insert([{
        employee_id: id,
        amount,
        payment_method
      }])
      .select();

    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (error) {
    console.error('Error paying salary:', error);
    res.status(500).json({ error: error.message });
  }
};

// Clock in an employee
exports.clockIn = async (req, res) => {
  try {
    const { id } = req.params;
    const { time } = req.body; // Custom time

    // Check if already clocked in
    const { data: existing, error: fetchError } = await supabaseAdmin
      .from('attendance')
      .select('*')
      .eq('employee_id', id)
      .is('clock_out', null);
      
    if (fetchError) throw fetchError;

    if (existing && existing.length > 0) {
      return res.status(400).json({ error: 'Employee is already clocked in' });
    }

    const { data, error } = await supabaseAdmin
      .from('attendance')
      .insert([{
        employee_id: id,
        clock_in: time ? new Date(time).toISOString() : new Date().toISOString()
      }])
      .select();

    if (error) throw error;

    res.status(200).json(data[0]);
  } catch (error) {
    console.error('Error clocking in:', error);
    res.status(500).json({ error: error.message });
  }
};

// Clock out an employee
exports.clockOut = async (req, res) => {
  try {
    const { id } = req.params;
    const { time } = req.body; // Custom time

    // Find open attendance record
    const { data: existing, error: fetchError } = await supabaseAdmin
      .from('attendance')
      .select('*')
      .eq('employee_id', id)
      .is('clock_out', null)
      .single();
      
    if (fetchError) {
      return res.status(400).json({ error: 'No active clock-in record found' });
    }

    const clockOutTime = time ? new Date(time) : new Date();
    const clockInTime = new Date(existing.clock_in);
    const diffHrs = (clockOutTime - clockInTime) / (1000 * 60 * 60);

    const { data, error } = await supabaseAdmin
      .from('attendance')
      .update({
        clock_out: clockOutTime.toISOString(),
        hours_worked: diffHrs
      })
      .eq('id', existing.id)
      .select();

    if (error) throw error;

    res.status(200).json(data[0]);
  } catch (error) {
    console.error('Error clocking out:', error);
    res.status(500).json({ error: error.message });
  }
};
