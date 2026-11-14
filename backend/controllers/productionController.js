const { createClient } = require('@supabase/supabase-js');

// Create admin client bypassing RLS using SERVICE_ROLE_KEY
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL || 'https://placeholder.supabase.co',
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || 'placeholder-key',
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// Default Pre-defined Factory Products & Step Recipes (used as immediate fallback if DB tables not seeded yet)
const DEFAULT_PRODUCTS = [
  {
    id: 'prod-pencil-brown',
    name: 'Brown Pencil',
    category: 'Pencils',
    description: 'Graphite paper-rolled brown pencil',
    color: '#8D6E63',
    steps: [
      { step_number: 1, process_name: 'Paper Cutting', expected_tolerance_pct: 3.0 },
      { step_number: 2, process_name: 'Rolling & Glueing', expected_tolerance_pct: 4.0 },
      { step_number: 3, process_name: 'Drying', expected_tolerance_pct: 2.0 },
      { step_number: 4, process_name: 'Lead Insertion', expected_tolerance_pct: 3.0 },
      { step_number: 5, process_name: 'Polishing & Shaping', expected_tolerance_pct: 5.0 },
      { step_number: 6, process_name: 'Final Packaging', expected_tolerance_pct: 1.0 },
    ]
  },
  {
    id: 'prod-pencil-white',
    name: 'White Pencil',
    category: 'Pencils',
    description: 'Premium polymer-coated white pencil',
    color: '#64748B',
    steps: [
      { step_number: 1, process_name: 'Paper Cutting', expected_tolerance_pct: 3.0 },
      { step_number: 2, process_name: 'Rolling', expected_tolerance_pct: 4.0 },
      { step_number: 3, process_name: 'Bleaching & Coating', expected_tolerance_pct: 4.0 },
      { step_number: 4, process_name: 'Drying', expected_tolerance_pct: 2.0 },
      { step_number: 5, process_name: 'Polishing', expected_tolerance_pct: 5.0 },
      { step_number: 6, process_name: 'Packaging', expected_tolerance_pct: 1.0 },
    ]
  },
  {
    id: 'prod-eraser-red',
    name: 'Eraser (Red)',
    category: 'Erasers',
    description: 'Soft vinyl non-dust eraser in red',
    color: '#EF4444',
    steps: [
      { step_number: 1, process_name: 'Rubber Compounding', expected_tolerance_pct: 4.0 },
      { step_number: 2, process_name: 'Dye Mixing (Red)', expected_tolerance_pct: 2.0 },
      { step_number: 3, process_name: 'Extrusion & Molding', expected_tolerance_pct: 5.0 },
      { step_number: 4, process_name: 'Cooling & Slicing', expected_tolerance_pct: 3.0 },
      { step_number: 5, process_name: 'Quality Inspection & Packing', expected_tolerance_pct: 2.0 },
    ]
  },
  {
    id: 'prod-eraser-blue',
    name: 'Eraser (Blue)',
    category: 'Erasers',
    description: 'Drafting non-smudge eraser in blue',
    color: '#3B82F6',
    steps: [
      { step_number: 1, process_name: 'Rubber Compounding', expected_tolerance_pct: 4.0 },
      { step_number: 2, process_name: 'Dye Mixing (Blue)', expected_tolerance_pct: 2.0 },
      { step_number: 3, process_name: 'Extrusion & Molding', expected_tolerance_pct: 5.0 },
      { step_number: 4, process_name: 'Cooling & Slicing', expected_tolerance_pct: 3.0 },
      { step_number: 5, process_name: 'Quality Inspection & Packing', expected_tolerance_pct: 2.0 },
    ]
  }
];

// ─── 1. GET ALL PRODUCT TYPES & PRE-DEFINED STEPS ────────────────────────────
exports.getProductTypes = async (req, res) => {
  try {
    const { data: products, error } = await supabaseAdmin
      .from('production_products')
      .select('*, production_process_templates(*)')
      .order('created_at', { ascending: true });

    if (error || !products || products.length === 0) {
      // Fallback to seeded in-memory templates
      return res.status(200).json(DEFAULT_PRODUCTS);
    }

    const formatted = products.map(p => ({
      id: p.id,
      name: p.name,
      category: p.category,
      description: p.description,
      color: p.color,
      steps: (p.production_process_templates || []).sort((a, b) => a.step_number - b.step_number)
    }));

    res.status(200).json(formatted);
  } catch (err) {
    console.warn('getProductTypes fallback used:', err.message);
    res.status(200).json(DEFAULT_PRODUCTS);
  }
};

// ─── 2. CREATE PRODUCT TYPE (Admin) ──────────────────────────────────────────
exports.createProductType = async (req, res) => {
  try {
    const { name, category, description, color, steps } = req.body;
    if (!name) return res.status(400).json({ error: 'Product name is required' });

    const { data: product, error: pErr } = await supabaseAdmin
      .from('production_products')
      .insert([{ name, category, description, color }])
      .select()
      .single();

    if (pErr) throw pErr;

    if (Array.isArray(steps) && steps.length > 0) {
      const stepRows = steps.map((s, idx) => ({
        product_id: product.id,
        step_number: s.step_number || (idx + 1),
        process_name: s.process_name || s.name || `Step ${idx + 1}`,
        expected_tolerance_pct: s.expected_tolerance_pct || 5.0,
      }));
      await supabaseAdmin.from('production_process_templates').insert(stepRows);
    }

    res.status(201).json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── 3. DELETE PRODUCT TYPE (Admin) ──────────────────────────────────────────
exports.deleteProductType = async (req, res) => {
  try {
    const { id } = req.params;
    await supabaseAdmin.from('production_process_templates').delete().eq('product_id', id);
    const { error } = await supabaseAdmin.from('production_products').delete().eq('id', id);
    if (error) throw error;
    res.status(200).json({ success: true, message: 'Product type deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── 4. GET PRODUCTION ORDERS ────────────────────────────────────────────────
exports.getOrders = async (req, res) => {
  try {
    const { data: orders, error } = await supabaseAdmin
      .from('production_orders')
      .select('*, production_logs(*)')
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.status(200).json(orders);
  } catch (error) {
    console.error('Error fetching production orders:', error);
    res.status(500).json({ error: error.message });
  }
};

// ─── 5. CREATE PRODUCTION ORDER ──────────────────────────────────────────────
exports.createOrder = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { product_name, product_id, batch_code } = req.body;

    if (!product_name) {
      return res.status(400).json({ error: 'Product name is required' });
    }

    const { data, error } = await supabaseAdmin
      .from('production_orders')
      .insert([{
        owner_id: userId,
        product_name,
        status: 'In Progress'
      }])
      .select();

    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (error) {
    console.error('Error creating production order:', error);
    res.status(500).json({ error: error.message });
  }
};

// ─── 6. COMPLETE PRODUCTION ORDER ────────────────────────────────────────────
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

// ─── 7. ADD PROCESS LOG (Step Recording) ─────────────────────────────────────
exports.addProcessLog = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { id: order_id } = req.params;
    const { process_name, step_number, input_item_id, input_qty, output_qty } = req.body;

    if (!process_name) {
      return res.status(400).json({ error: 'Process name is required' });
    }

    const inQty = parseFloat(input_qty || 0);
    const outQty = parseFloat(output_qty || 0);
    const wasteQty = Math.max(0, inQty - outQty);

    const { data: logData, error: logError } = await supabaseAdmin
      .from('production_logs')
      .insert([{
        owner_id: userId,
        order_id,
        process_name,
        input_item_id: input_item_id || null,
        input_qty: inQty,
        output_qty: outQty,
        wastage_qty: wasteQty
      }])
      .select();

    if (logError) throw logError;

    // Trigger low stock notification if raw material is low
    if (input_item_id) {
      try {
        const { data: itemData } = await supabaseAdmin
          .from('items')
          .select('title, stock_quantity, min_quantity')
          .eq('id', input_item_id)
          .single();

        if (itemData && parseFloat(itemData.stock_quantity || 0) <= parseFloat(itemData.min_quantity || 0)) {
          await supabaseAdmin.from('notifications').insert([{
            user_id: userId,
            title: 'Low Stock Alert',
            message: `Stock for ${itemData.title} has fallen to ${itemData.stock_quantity} (Minimum: ${itemData.min_quantity}). Please restock!`,
            is_read: false
          }]);
        }
      } catch (e) {
        console.warn('Low stock check ignored:', e.message);
      }
    }

    res.status(201).json(logData[0]);
  } catch (error) {
    console.error('Error adding process log:', error);
    res.status(500).json({ error: error.message });
  }
};

// ─── 8. UPDATE PROCESS LOG OUTPUT ────────────────────────────────────────────
exports.updateProcessLog = async (req, res) => {
  try {
    const { logId } = req.params;
    const { output_qty } = req.body;

    if (output_qty === undefined) {
      return res.status(400).json({ error: 'Output quantity is required' });
    }

    // Fetch existing log to calculate wastage
    const { data: existing } = await supabaseAdmin
      .from('production_logs')
      .select('input_qty')
      .eq('id', logId)
      .single();

    const inQty = existing ? parseFloat(existing.input_qty || 0) : 0;
    const outQty = parseFloat(output_qty || 0);
    const wasteQty = Math.max(0, inQty - outQty);

    const { data, error } = await supabaseAdmin
      .from('production_logs')
      .update({
        output_qty: outQty,
        wastage_qty: wasteQty
      })
      .eq('id', logId)
      .select();

    if (error) throw error;
    res.status(200).json(data[0]);
  } catch (error) {
    console.error('Error updating process log:', error);
    res.status(500).json({ error: error.message });
  }
};

// ─── 9. MACHINE LEARNING & STATISTICAL WASTAGE REPORT ────────────────────────
exports.getWastageReport = async (req, res) => {
  try {
    const { start_date, end_date, horizon } = req.query;

    // 1. Fetch all production logs joined with order details safely
    let query = supabaseAdmin
      .from('production_logs')
      .select('id, order_id, process_name, input_qty, output_qty, wastage_qty, created_at, production_orders(id, product_name, status, created_at)')
      .order('created_at', { ascending: false });

    if (start_date) query = query.gte('created_at', start_date);
    if (end_date) query = query.lte('created_at', end_date);

    const { data: rawLogs, error } = await query;
    if (error) {
      console.warn('Fallback simple query for production_logs:', error.message);
      // Fallback without embedded relationship
      const { data: simpleLogs, error: sErr } = await supabaseAdmin
        .from('production_logs')
        .select('*')
        .order('created_at', { ascending: false });
      if (sErr) throw sErr;
      return res.status(200).json(_computeWastageAnalytics(simpleLogs || []));
    }

    const report = _computeWastageAnalytics(rawLogs || []);
    res.status(200).json(report);
  } catch (error) {
    console.error('Error in getWastageReport:', error.message);
    res.status(500).json({ error: error.message });
  }
};

// ─── ML & ANALYTICS CALCULATION ENGINE ───────────────────────────────────────
function _computeWastageAnalytics(logs) {
  let grandTotalInput = 0;
  let grandTotalOutput = 0;
  let grandTotalWastage = 0;

  // Process stats accumulator: process_name -> array of rates
  const processStats = {};
  // Production batch accumulator: order_id -> batch object
  const batchMap = {};
  // Time horizon accumulators
  const dailyMap = {};
  const weeklyMap = {};
  const monthlyMap = {};
  const yearlyMap = {};

  const cleanLogs = logs.map(l => {
    const inQty = Number(l.input_qty || 0);
    const outQty = Number(l.output_qty || 0);
    const wasteQty = Number(l.wastage_qty !== undefined ? l.wastage_qty : Math.max(0, inQty - outQty));
    const wastePct = inQty > 0 ? (wasteQty / inQty) * 100 : 0;
    const yieldPct = inQty > 0 ? (outQty / inQty) * 100 : (outQty > 0 ? 100 : 0);

    grandTotalInput += inQty;
    grandTotalOutput += outQty;
    grandTotalWastage += wasteQty;

    const procName = l.process_name || 'Standard Step';
    if (!processStats[procName]) {
      processStats[procName] = {
        process_name: procName,
        total_input: 0,
        total_output: 0,
        total_wastage: 0,
        samples: [],
      };
    }
    processStats[procName].total_input += inQty;
    processStats[procName].total_output += outQty;
    processStats[procName].total_wastage += wasteQty;
    processStats[procName].samples.push(wastePct);

    // Group by Batch / Production Order
    const orderId = l.order_id || 'unassigned';
    const productName = l.production_orders?.product_name || 'Standard Production';
    if (!batchMap[orderId]) {
      batchMap[orderId] = {
        order_id: orderId,
        product_name: productName,
        status: l.production_orders?.status || 'In Progress',
        created_at: l.created_at,
        total_input: 0,
        total_output: 0,
        total_wastage: 0,
        steps: [],
        bottleneck_step: null,
        max_step_waste: -1
      };
    }
    batchMap[orderId].total_input += inQty;
    batchMap[orderId].total_output += outQty;
    batchMap[orderId].total_wastage += wasteQty;
    batchMap[orderId].steps.push({
      id: l.id,
      process_name: procName,
      input_qty: inQty,
      output_qty: outQty,
      wastage_qty: wasteQty,
      wastage_pct: parseFloat(wastePct.toFixed(2)),
      yield_pct: parseFloat(yieldPct.toFixed(2)),
      created_at: l.created_at
    });
    if (wasteQty > batchMap[orderId].max_step_waste) {
      batchMap[orderId].max_step_waste = wasteQty;
      batchMap[orderId].bottleneck_step = procName;
    }

    // Time Horizons
    const d = new Date(l.created_at || Date.now());
    const dayKey = d.toISOString().split('T')[0]; // YYYY-MM-DD
    const monthKey = dayKey.substring(0, 7); // YYYY-MM
    const yearKey = dayKey.substring(0, 4); // YYYY
    const weekNum = _getWeekNumber(d);
    const weekKey = `${yearKey}-W${weekNum < 10 ? '0' + weekNum : weekNum}`;

    _accumulateTime(dailyMap, dayKey, inQty, outQty, wasteQty);
    _accumulateTime(weeklyMap, weekKey, inQty, outQty, wasteQty);
    _accumulateTime(monthlyMap, monthKey, inQty, outQty, wasteQty);
    _accumulateTime(yearlyMap, yearKey, inQty, outQty, wasteQty);

    return {
      ...l,
      input_qty: inQty,
      output_qty: outQty,
      wastage_qty: wasteQty,
      wastage_pct: parseFloat(wastePct.toFixed(2)),
      yield_pct: parseFloat(yieldPct.toFixed(2)),
      product_name: productName
    };
  });

  // Calculate ML Baselines & Z-score Anomalies per process
  const byProcess = Object.values(processStats).map(ps => {
    const n = ps.samples.length;
    const mean = n > 0 ? ps.samples.reduce((a, b) => a + b, 0) / n : 0;
    const variance = n > 1 ? ps.samples.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / (n - 1) : 0;
    const stdDev = Math.sqrt(variance);
    const avgYield = ps.total_input > 0 ? (ps.total_output / ps.total_input) * 100 : 0;
    const avgWaste = ps.total_input > 0 ? (ps.total_wastage / ps.total_input) * 100 : 0;
    const baselineTolerance = 5.0; // 5% default standard

    return {
      process_name: ps.process_name,
      total_input: ps.total_input,
      total_output: ps.total_output,
      total_wastage: ps.total_wastage,
      yield_pct: parseFloat(avgYield.toFixed(2)),
      wastage_pct: parseFloat(avgWaste.toFixed(2)),
      mean_wastage_rate: parseFloat(mean.toFixed(2)),
      std_dev: parseFloat(stdDev.toFixed(2)),
      tolerance_pct: baselineTolerance,
      sample_count: n
    };
  });

  // Flag ML anomalies on individual logs
  const processMeta = {};
  byProcess.forEach(p => { processMeta[p.process_name] = p; });

  const anomalies = [];
  cleanLogs.forEach(l => {
    const meta = processMeta[l.process_name];
    if (!meta) return;

    const std = meta.std_dev || 1.0;
    const zScore = meta.std_dev > 0 ? (l.wastage_pct - meta.mean_wastage_rate) / std : 0;

    // Anomaly condition: Z > 2.0 OR wastage_pct > (tolerance * 1.5)
    if (l.input_qty > 0 && (zScore > 2.0 || l.wastage_pct > (meta.tolerance_pct * 1.5))) {
      const anomalyObj = {
        log_id: l.id,
        order_id: l.order_id,
        product_name: l.product_name,
        process_name: l.process_name,
        input_qty: l.input_qty,
        output_qty: l.output_qty,
        wastage_qty: l.wastage_qty,
        wastage_pct: l.wastage_pct,
        z_score: parseFloat(zScore.toFixed(2)),
        expected_tolerance: meta.tolerance_pct,
        baseline_mean: meta.mean_wastage_rate,
        severity: zScore > 3.0 ? 'Critical' : 'High',
        created_at: l.created_at
      };
      anomalies.push(anomalyObj);
      l.is_anomaly = true;
      l.anomaly_severity = anomalyObj.severity;
    }
  });

  // Calculate overall yield & efficiency grade
  const overallYield = grandTotalInput > 0 ? (grandTotalOutput / grandTotalInput) * 100 : 0;
  const overallWaste = grandTotalInput > 0 ? (grandTotalWastage / grandTotalInput) * 100 : 0;

  let grade = 'D';
  if (overallYield >= 96) grade = 'A+';
  else if (overallYield >= 92) grade = 'A';
  else if (overallYield >= 85) grade = 'B';
  else if (overallYield >= 75) grade = 'C';

  // Format batches
  const byProduction = Object.values(batchMap).map(b => {
    const yPct = b.total_input > 0 ? (b.total_output / b.total_input) * 100 : 0;
    const wPct = b.total_input > 0 ? (b.total_wastage / b.total_input) * 100 : 0;
    return {
      order_id: b.order_id,
      product_name: b.product_name,
      status: b.status,
      created_at: b.created_at,
      total_input: b.total_input,
      total_output: b.total_output,
      total_wastage: b.total_wastage,
      yield_pct: parseFloat(yPct.toFixed(2)),
      wastage_pct: parseFloat(wPct.toFixed(2)),
      bottleneck_step: b.bottleneck_step || 'None',
      steps: b.steps
    };
  });

  return {
    summary: {
      total_input: grandTotalInput,
      total_output: grandTotalOutput,
      total_wastage: grandTotalWastage,
      overall_yield_pct: parseFloat(overallYield.toFixed(2)),
      overall_wastage_pct: parseFloat(overallWaste.toFixed(2)),
      anomaly_count: anomalies.length,
      efficiency_grade: grade,
      batch_count: byProduction.length,
      total_logs_analyzed: cleanLogs.length,
      model_type: 'Gaussian Z-Score Anomaly Detector & Statistical Yield Predictor'
    },
    by_production: byProduction,
    by_process: byProcess,
    daily: _mapToArray(dailyMap, 'date'),
    weekly: _mapToArray(weeklyMap, 'week'),
    monthly: _mapToArray(monthlyMap, 'month'),
    yearly: _mapToArray(yearlyMap, 'year'),
    anomalies: anomalies,
    raw_logs: cleanLogs
  };
}

function _accumulateTime(map, key, inQty, outQty, wasteQty) {
  if (!map[key]) {
    map[key] = { key, total_input: 0, total_output: 0, total_wastage: 0, count: 0 };
  }
  map[key].total_input += inQty;
  map[key].total_output += outQty;
  map[key].total_wastage += wasteQty;
  map[key].count += 1;
}

function _mapToArray(map, keyName) {
  return Object.values(map)
    .sort((a, b) => b.key.localeCompare(a.key))
    .map(item => {
      const yieldPct = item.total_input > 0 ? (item.total_output / item.total_input) * 100 : 0;
      const wastePct = item.total_input > 0 ? (item.total_wastage / item.total_input) * 100 : 0;
      return {
        [keyName]: item.key,
        total_input: item.total_input,
        total_output: item.total_output,
        total_wastage: item.total_wastage,
        yield_pct: parseFloat(yieldPct.toFixed(2)),
        wastage_pct: parseFloat(wastePct.toFixed(2)),
        log_count: item.count
      };
    });
}

function _getWeekNumber(d) {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const dayNum = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  return Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
}

// ─── 10. EXPORT WASTAGE REPORT IN EXCEL / CSV ────────────────────────────────
exports.exportWastageExcel = async (req, res) => {
  try {
    const { data: rawLogs } = await supabaseAdmin
      .from('production_logs')
      .select('id, order_id, process_name, input_qty, output_qty, wastage_qty, created_at, production_orders(product_name, status)')
      .order('created_at', { ascending: false });

    const analytics = _computeWastageAnalytics(rawLogs || []);

    // Build CSV content
    const headers = [
      'Record ID',
      'Production Order ID',
      'Product Name',
      'Process Step',
      'Date & Time',
      'Input Qty',
      'Output Qty',
      'Wastage Qty',
      'Wastage Rate (%)',
      'Yield Rate (%)',
      'ML Anomaly Flag'
    ];

    const rows = [headers.join(',')];

    (analytics.raw_logs || []).forEach(l => {
      const row = [
        `"${l.id || ''}"`,
        `"${l.order_id || ''}"`,
        `"${(l.product_name || 'Standard').replace(/"/g, '""')}"`,
        `"${(l.process_name || '').replace(/"/g, '""')}"`,
        `"${l.created_at || ''}"`,
        l.input_qty,
        l.output_qty,
        l.wastage_qty,
        `${l.wastage_pct}%`,
        `${l.yield_pct}%`,
        l.is_anomaly ? `"${l.anomaly_severity || 'ANOMALY'}"` : '"Normal"'
      ];
      rows.push(row.join(','));
    });

    const csvData = '\uFEFF' + rows.join('\r\n'); // Add UTF-8 BOM for Microsoft Excel

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="buoy-factory-wastage-report.csv"');
    res.status(200).send(csvData);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ─── 11. EXPORT WASTAGE REPORT IN EXECUTIVE PRINTABLE PDF / HTML ─────────────
exports.exportWastagePdf = async (req, res) => {
  try {
    const { data: rawLogs } = await supabaseAdmin
      .from('production_logs')
      .select('id, order_id, process_name, input_qty, output_qty, wastage_qty, created_at, production_orders(product_name, status)')
      .order('created_at', { ascending: false });

    const report = _computeWastageAnalytics(rawLogs || []);
    const s = report.summary;

    const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Buoy Factory - Official Wastage & Yield Executive Report</title>
  <style>
    @media print {
      body { margin: 0; padding: 15mm; }
      .no-print { display: none; }
    }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; color: #0F172A; background: #fff; margin: 30px; font-size: 13px; line-height: 1.5; }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #E2E8F0; padding-bottom: 20px; margin-bottom: 24px; }
    .logo-title { font-size: 22px; font-weight: 800; color: #2563EB; letter-spacing: -0.5px; }
    .sub-title { font-size: 13px; color: #64748B; font-weight: 500; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
    .badge-grade { background: #10B981; color: white; }
    .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 28px; }
    .kpi-card { background: #F8FAFC; border: 1.2px solid #E2E8F0; border-radius: 12px; padding: 14px; }
    .kpi-label { font-size: 11px; color: #64748B; text-transform: uppercase; font-weight: 700; margin-bottom: 4px; }
    .kpi-val { font-size: 24px; font-weight: 800; color: #0F172A; }
    .kpi-val.green { color: #10B981; }
    .kpi-val.red { color: #EF4444; }
    .section-title { font-size: 16px; font-weight: 700; margin: 24px 0 12px; display: flex; justify-content: space-between; align-items: center; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 12.5px; }
    th { background: #F1F5F9; color: #475569; font-weight: 700; text-align: left; padding: 10px; border: 1px solid #E2E8F0; }
    td { padding: 9px 10px; border: 1px solid #E2E8F0; }
    tr:nth-child(even) td { background: #FAFAFA; }
    .bar-container { background: #E2E8F0; border-radius: 4px; height: 10px; width: 100%; overflow: hidden; margin-top: 4px; }
    .bar-fill { background: #10B981; height: 100%; }
    .anomaly-row { background: #FEF2F2 !important; color: #991B1B; font-weight: 600; }
    .print-btn { background: #2563EB; color: #fff; border: none; padding: 10px 18px; border-radius: 8px; font-weight: 600; cursor: pointer; }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="logo-title">BUOY ERP — FACTORY INTELLIGENCE</div>
      <div class="sub-title">Automated ML Wastage & Yield Efficiency Executive Audit</div>
    </div>
    <div style="text-align: right;">
      <button class="print-btn no-print" onclick="window.print()">Print / Save as PDF</button>
      <div style="font-size: 11px; color: #64748B; margin-top: 6px;">Generated: ${new Date().toLocaleString()}</div>
    </div>
  </div>

  <div class="kpi-grid">
    <div class="kpi-card">
      <div class="kpi-label">Overall Plant Yield</div>
      <div class="kpi-val green">${s.overall_yield_pct}%</div>
      <div style="font-size: 11px; color: #64748B;">Efficiency Grade: <span class="badge badge-grade">${s.efficiency_grade}</span></div>
    </div>
    <div class="kpi-card">
      <div class="kpi-label">Total Raw Material Input</div>
      <div class="kpi-val">${s.total_input.toLocaleString()}</div>
      <div style="font-size: 11px; color: #64748B;">Units across ${s.batch_count} batches</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-label">Total Factory Wastage</div>
      <div class="kpi-val red">${s.total_wastage.toLocaleString()}</div>
      <div style="font-size: 11px; color: #EF4444;">Rate: ${s.overall_wastage_pct}% loss</div>
    </div>
    <div class="kpi-card">
      <div class="kpi-label">ML Anomaly Alerts</div>
      <div class="kpi-val ${s.anomaly_count > 0 ? 'red' : 'green'}">${s.anomaly_count}</div>
      <div style="font-size: 11px; color: #64748B;">Outlier steps flagged (Z > 2.0)</div>
    </div>
  </div>

  <div class="section-title">Stage-by-Stage Process Breakdown & Loss Benchmarks</div>
  <table>
    <thead>
      <tr>
        <th>Process Stage</th>
        <th>Total Input</th>
        <th>Total Output</th>
        <th>Net Wastage</th>
        <th>Avg Loss %</th>
        <th>Tolerance</th>
        <th>Yield Rate Visual</th>
      </tr>
    </thead>
    <tbody>
      ${report.by_process.map(p => `
        <tr>
          <td><strong>${p.process_name}</strong></td>
          <td>${p.total_input.toLocaleString()}</td>
          <td>${p.total_output.toLocaleString()}</td>
          <td style="color: #EF4444;">${p.total_wastage.toLocaleString()}</td>
          <td><strong>${p.wastage_pct}%</strong></td>
          <td>${p.tolerance_pct}%</td>
          <td style="width: 140px;">
            ${p.yield_pct}%
            <div class="bar-container">
              <div class="bar-fill" style="width: ${Math.min(100, Math.max(0, p.yield_pct))}%;"></div>
            </div>
          </td>
        </tr>
      `).join('')}
    </tbody>
  </table>

  <div class="section-title">Production Batches Performance Audit</div>
  <table>
    <thead>
      <tr>
        <th>Batch Order ID</th>
        <th>Product Type</th>
        <th>Status</th>
        <th>Input</th>
        <th>Output</th>
        <th>Wastage</th>
        <th>Yield %</th>
        <th>Bottleneck Process</th>
      </tr>
    </thead>
    <tbody>
      ${report.by_production.map(b => `
        <tr>
          <td><code style="font-size: 11px;">${b.order_id.substring(0, 8)}...</code></td>
          <td><strong>${b.product_name}</strong></td>
          <td>${b.status}</td>
          <td>${b.total_input.toLocaleString()}</td>
          <td>${b.total_output.toLocaleString()}</td>
          <td style="color: #EF4444;">${b.total_wastage.toLocaleString()}</td>
          <td><strong>${b.yield_pct}%</strong></td>
          <td>${b.bottleneck_step}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>

  <div style="margin-top: 30px; padding: 14px; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; font-size: 11px; color: #64748B; text-align: center;">
    Official Buoy ERP Industrial Report • Model: ${s.model_type} • Certified for Client Audits
  </div>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
