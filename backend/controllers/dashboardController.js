const { getClient, supabaseAdmin } = require('../config/supabase');

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
      getClient(req)
        .from('items')
        .select('id', { count: 'exact', head: true }),

      // Active production orders (global factory)
      getClient(req)
        .from('production_orders')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'In Progress'),

      // Process logs today (global factory)
      getClient(req)
        .from('production_logs')
        .select('id', { count: 'exact', head: true })
        .gte('created_at', new Date(new Date().setHours(0, 0, 0, 0)).toISOString()),

      // Total employees (global factory)
      getClient(req)
        .from('employees')
        .select('id', { count: 'exact', head: true }),

      // Employees currently clocked in (global factory)
      getClient(req)
        .from('attendance')
        .select('id', { count: 'exact', head: true })
        .is('clock_out', null),
    ]);

    // Low stock needs a separate query
    const { data: allItems } = await getClient(req)
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
