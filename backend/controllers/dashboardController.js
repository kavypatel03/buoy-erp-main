const { createClient } = require('@supabase/supabase-js');

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// GET /api/dashboard/summary
// Returns: total inventory items, low stock count, active production orders,
//          active process logs (today), employees clocked in
exports.getSummary = async (req, res) => {
  try {
    const userId = req.user.id;

    // Run all queries in parallel for speed
    const [
      itemsResult,
      ordersResult,
      logsResult,
      employeesResult,
      clockedInResult,
    ] = await Promise.all([
      // Total inventory items (items table has no owner_id)
      supabaseAdmin
        .from('items')
        .select('id', { count: 'exact', head: true }),

      // Active production orders
      supabaseAdmin
        .from('production_orders')
        .select('id', { count: 'exact', head: true })
        .eq('owner_id', userId)
        .eq('status', 'In Progress'),

      // Process logs today
      supabaseAdmin
        .from('production_logs')
        .select('id', { count: 'exact', head: true })
        .eq('owner_id', userId)
        .gte('created_at', new Date(new Date().setHours(0, 0, 0, 0)).toISOString()),

      // Total employees
      supabaseAdmin
        .from('employees')
        .select('id', { count: 'exact', head: true })
        .eq('owner_id', userId),

      // Employees currently clocked in
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
