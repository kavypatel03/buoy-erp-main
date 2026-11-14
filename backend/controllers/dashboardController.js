const { createClient } = require('@supabase/supabase-js');

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL || 'https://placeholder.supabase.co',
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || 'placeholder-key',
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// GET /api/dashboard/summary
// Returns: total inventory items, low stock count, active production orders,
//          active process logs (today), employees clocked in (global factory view)
exports.getSummary = async (req, res) => {
  try {
    // Run all queries in parallel for speed across the shared factory data
    const [
      itemsResult,
      ordersResult,
      logsResult,
      employeesResult,
      clockedInResult,
    ] = await Promise.all([
      // Total inventory items
      supabaseAdmin
        .from('items')
        .select('id', { count: 'exact', head: true }),

      // Active production orders (global factory)
      supabaseAdmin
        .from('production_orders')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'In Progress'),

      // Process logs today (global factory)
      supabaseAdmin
        .from('production_logs')
        .select('id', { count: 'exact', head: true })
        .gte('created_at', new Date(new Date().setHours(0, 0, 0, 0)).toISOString()),

      // Total employees (global factory)
      supabaseAdmin
        .from('employees')
        .select('id', { count: 'exact', head: true }),

      // Employees currently clocked in (global factory)
      supabaseAdmin
        .from('attendance')
        .select('id', { count: 'exact', head: true })
        .is('clock_out', null),
    ]);

    // Low stock needs a separate query
    const { data: allItems } = await supabaseAdmin
      .from('items')
      .select('stock_quantity, min_quantity');

    const lowStockCount = (allItems || []).filter(
      (item) => parseFloat(item.stock_quantity || 0) <= parseFloat(item.min_quantity || 0)
    ).length;

    res.status(200).json({
      totalItems: itemsResult.count ?? 0,
      lowStockItems: lowStockCount,
      activeOrders: ordersResult.count ?? 0,
      logsToday: logsResult.count ?? 0,
      totalEmployees: employeesResult.count ?? 0,
      clockedInEmployees: clockedInResult.count ?? 0,
    });
  } catch (error) {
    console.error('Error fetching dashboard summary:', error);
    res.status(500).json({ error: error.message });
  }
};
