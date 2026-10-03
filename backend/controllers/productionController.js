const { createClient } = require('@supabase/supabase-js');

// Create admin client bypassing RLS using SERVICE_ROLE_KEY
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// 1. Get all production orders for the current user
exports.getOrders = async (req, res) => {
  try {
    const userId = req.user.id;

    // Fetch orders and their associated logs
    const { data: orders, error } = await supabaseAdmin
      .from('production_orders')
      .select('*, production_logs(*)')
      .eq('owner_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.status(200).json(orders);
  } catch (error) {
    console.error('Error fetching production orders:', error);
    res.status(500).json({ error: error.message });
  }
};

// 2. Create a new production order
exports.createOrder = async (req, res) => {
  try {
    const userId = req.user.id;
    const { product_name } = req.body;

    if (!product_name) {
      return res.status(400).json({ error: 'Product name is required' });
    }

    const { data, error } = await supabaseAdmin
      .from('production_orders')
      .insert([{ owner_id: userId, product_name }])
      .select();

    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (error) {
    console.error('Error creating production order:', error);
    res.status(500).json({ error: error.message });
  }
};

// 3. Mark an order as completed
exports.completeOrder = async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabaseAdmin
      .from('production_orders')
      .update({ status: 'Completed', end_date: new Date().toISOString() })
      .eq('id', id)
      .select();

    if (error) throw error;
    res.status(200).json(data[0]);
  } catch (error) {
    console.error('Error completing order:', error);
    res.status(500).json({ error: error.message });
  }
};

// 4. Add a process log to an order (Automatically deducts from inventory via DB trigger)
exports.addProcessLog = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id: order_id } = req.params;
    const { process_name, input_item_id, input_qty, output_qty } = req.body;

    if (!process_name) {
      return res.status(400).json({ error: 'Process name is required' });
    }

    const { data: logData, error: logError } = await supabaseAdmin
      .from('production_logs')
      .insert([{
        owner_id: userId,
        order_id,
        process_name,
        input_item_id: input_item_id || null,
        input_qty: input_qty || 0,
        output_qty: output_qty || 0
      }])
      .select();

    if (logError) throw logError;

    // Check if the item stock hit minimum quantity to send notification
    if (input_item_id) {
      const { data: itemData, error: itemError } = await supabaseAdmin
        .from('items')
        .select('title, stock_quantity, min_quantity')
        .eq('id', input_item_id)
        .single();
      
      if (!itemError && itemData) {
        if (parseFloat(itemData.stock_quantity || 0) <= parseFloat(itemData.min_quantity || 0)) {
          // Trigger a low stock notification
          await supabaseAdmin.from('notifications').insert([{
            user_id: userId,
            title: 'Low Stock Alert',
            message: `Stock for ${itemData.title} has fallen to ${itemData.stock_quantity} (Minimum: ${itemData.min_quantity}). Please restock!`,
            is_read: false
          }]);
        }
      }
    }

    res.status(201).json(logData[0]);
  } catch (error) {
    console.error('Error adding process log:', error);
    res.status(500).json({ error: error.message });
  }
};

// 5. Get Wastage Report
exports.getWastageReport = async (req, res) => {
  try {
    const userId = req.user.id;
    // Optional filters: start_date, end_date
    const { start_date, end_date } = req.query;

    let query = supabaseAdmin
      .from('production_logs')
      .select('process_name, input_qty, output_qty, wastage_qty, created_at, items(name)')
      .eq('owner_id', userId)
      .order('created_at', { ascending: false });

    if (start_date) query = query.gte('created_at', start_date);
    if (end_date) query = query.lte('created_at', end_date);

    const { data: logs, error } = await query;
    if (error) throw error;

    // Aggregate wastage per process
    const aggregated = {};
    logs.forEach(log => {
      const proc = log.process_name;
      if (!aggregated[proc]) {
        aggregated[proc] = { process_name: proc, total_input: 0, total_output: 0, total_wastage: 0, logs: [] };
      }
      aggregated[proc].total_input += Number(log.input_qty);
      aggregated[proc].total_output += Number(log.output_qty);
      aggregated[proc].total_wastage += Number(log.wastage_qty);
      aggregated[proc].logs.push(log);
    });

    res.status(200).json(Object.values(aggregated));
  } catch (error) {
    console.error('Error generating wastage report:', error);
    res.status(500).json({ error: error.message });
  }
};

// 6. Update process log output
exports.updateProcessLog = async (req, res) => {
  try {
    const { logId } = req.params;
    const { output_qty } = req.body;

    if (output_qty === undefined) {
      return res.status(400).json({ error: 'Output quantity is required' });
    }

    const { data, error } = await supabaseAdmin
      .from('production_logs')
      .update({ output_qty })
      .eq('id', logId)
      .select();

    if (error) throw error;
    res.status(200).json(data[0]);
  } catch (error) {
    console.error('Error updating process log:', error);
    res.status(500).json({ error: error.message });
  }
};
