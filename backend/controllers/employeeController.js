const supabase = require('../config/supabase');

// Get all employees for the current user
exports.getEmployees = async (req, res) => {
  try {
    const userId = req.user.id;

    // Fetch employees
    const { data: employees, error: empError } = await supabase
      .from('employees')
      .select('*')
      .eq('owner_id', userId)
      .order('created_at', { ascending: false });

    if (empError) throw empError;

    // Fetch attendance to calculate total hours and salary
    const { data: attendance, error: attError } = await supabase
      .from('attendance')
      .select('*');

    if (attError) throw attError;

    const employeesWithStats = employees.map(emp => {
      const empAttendance = attendance.filter(a => a.employee_id === emp.id);
      
      let totalHours = 0;
      empAttendance.forEach(record => {
        if (record.clock_in && record.clock_out) {
          const diffMs = new Date(record.clock_out) - new Date(record.clock_in);
          const diffHrs = diffMs / (1000 * 60 * 60);
          totalHours += diffHrs;
        }
      });

      return {
        ...emp,
        total_hours: totalHours.toFixed(2),
        total_salary: (totalHours * emp.hourly_salary).toFixed(2),
        is_clocked_in: empAttendance.some(a => !a.clock_out)
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
    const { name, hourly_salary, profile_pic_url, phone, role, address } = req.body;

    if (!name || !hourly_salary) {
      return res.status(400).json({ error: 'Name and hourly salary are required' });
    }

    const { data, error } = await supabase
      .from('employees')
      .insert([{
        owner_id: userId,
        name,
        hourly_salary,
        profile_pic_url,
        phone,
        role,
        address
      }])
      .select();

    if (error) throw error;

    res.status(201).json(data[0]);
  } catch (error) {
    console.error('Error creating employee:', error);
    res.status(500).json({ error: error.message });
  }
};

// Clock in an employee
exports.clockIn = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if already clocked in
    const { data: existing, error: fetchError } = await supabase
      .from('attendance')
      .select('*')
      .eq('employee_id', id)
      .is('clock_out', null);
      
    if (fetchError) throw fetchError;

    if (existing && existing.length > 0) {
      return res.status(400).json({ error: 'Employee is already clocked in' });
    }

    const { data, error } = await supabase
      .from('attendance')
      .insert([{
        employee_id: id,
        clock_in: new Date().toISOString()
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

    // Find open attendance record
    const { data: existing, error: fetchError } = await supabase
      .from('attendance')
      .select('*')
      .eq('employee_id', id)
      .is('clock_out', null)
      .single();
      
    if (fetchError) {
      return res.status(400).json({ error: 'No active clock-in record found' });
    }

    const clockOutTime = new Date();
    const clockInTime = new Date(existing.clock_in);
    const diffHrs = (clockOutTime - clockInTime) / (1000 * 60 * 60);

    const { data, error } = await supabase
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
