const supabaseConfig = require('../config/supabase');
const { createClient } = require('@supabase/supabase-js');
const admin = require('firebase-admin');

// Create admin client bypassing RLS using SERVICE_ROLE_KEY if available
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL || 'https://placeholder.supabase.co',
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_PUBLISHABLE_KEY || 'placeholder-key',
  { auth: { autoRefreshToken: false, persistSession: false } }
);

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

exports.getLogin = (req, res) => {
  res.render('login', { error: null });
};

exports.postLogin = (req, res) => {
  const { email, password } = req.body;
  if (email === 'mtkv@gmail.com' && password === 'mtkv2004@2005') {
    res.cookie('admin_auth', 'true', {
      signed: true,
      httpOnly: true,
      sameSite: 'lax',
      secure: process.env.NODE_ENV === 'production'
    });
    res.redirect('/admin');
  } else {
    res.render('login', { error: 'Invalid admin credentials' });
  }
};

exports.logout = (req, res) => {
  res.clearCookie('admin_auth', {
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production'
  });
  res.redirect('/admin/login');
};

exports.getDashboard = async (req, res) => {
  try {
    const [usersResult, settingsResult, productsResult, statsResult, apkSettingsResult] = await Promise.allSettled([
      supabaseAdmin.auth.admin.listUsers(),
      supabaseAdmin.from('app_settings').select('value').eq('key', 'registration_enabled').maybeSingle(),
      supabaseAdmin.from('production_products').select('*, production_process_templates(*)').order('created_at', { ascending: true }),
      Promise.all([
        supabaseAdmin.from('items').select('id', { count: 'exact', head: true }),
        supabaseAdmin.from('employees').select('id', { count: 'exact', head: true }),
        supabaseAdmin.from('production_orders').select('id', { count: 'exact', head: true }),
        supabaseAdmin.from('production_logs').select('id', { count: 'exact', head: true }),
      ]),
      supabaseAdmin.from('app_settings').select('*').in('key', ['apk_download_url', 'apk_version']),
    ]);

    // Extract users
    let users = [];
    if (usersResult.status === 'fulfilled') {
      const { data, error } = usersResult.value;
      if (!error && data?.users) users = data.users;
    } else {
      console.warn('listUsers warning:', usersResult.reason?.message);
    }

    // Extract registration setting
    let regEnabled = true;
    if (settingsResult.status === 'fulfilled') {
      const { data: settingsData } = settingsResult.value;
      if (settingsData) {
        regEnabled = settingsData.value === 'true' || settingsData.value === true;
      }
    }

    // Extract products
    let products = [];
    if (productsResult.status === 'fulfilled') {
      const { data: dbProducts } = productsResult.value;
      if (dbProducts && dbProducts.length > 0) {
        products = dbProducts.map(p => ({
          ...p,
          steps: (p.production_process_templates || []).sort((a, b) => a.step_number - b.step_number)
        }));
      } else {
        products = DEFAULT_PRODUCTS;
      }
    } else {
      products = DEFAULT_PRODUCTS;
    }

    // Extract stats
    const stats = { items: 0, employees: 0, orders: 0, logs: 0 };
    if (statsResult.status === 'fulfilled') {
      const [itRes, empRes, ordRes, logRes] = statsResult.value;
      stats.items = itRes.count || 0;
      stats.employees = empRes.count || 0;
      stats.orders = ordRes.count || 0;
      stats.logs = logRes.count || 0;
    }

    // Extract Release APK & OTA download settings
    let apkDownloadUrl = 'https://github.com/kavypatel03/buoy-erp-main/releases/latest/download/buoy-erp.apk';
    let apkVersion = '1.0.0';
    if (apkSettingsResult.status === 'fulfilled' && apkSettingsResult.value?.data) {
      const rows = apkSettingsResult.value.data;
      const urlRow = rows.find(r => r.key === 'apk_download_url');
      const verRow = rows.find(r => r.key === 'apk_version');
      if (urlRow?.value) apkDownloadUrl = urlRow.value;
      if (verRow?.value) apkVersion = verRow.value;
    }

    const successMsg = req.query.success || null;
    const errorMsg = req.query.error || null;

    res.render('dashboard', {
      users,
      regEnabled,
      products,
      stats,
      apkDownloadUrl,
      apkVersion,
      success: successMsg,
      error: errorMsg
    });
  } catch (err) {
    console.error('getDashboard error:', err);
    res.render('dashboard', {
      users: [],
      regEnabled: true,
      products: DEFAULT_PRODUCTS,
      stats: { items: 0, employees: 0, orders: 0, logs: 0 },
      apkDownloadUrl: 'https://github.com/kavypatel03/buoy-erp-main/releases/latest/download/buoy-erp.apk',
      apkVersion: '1.0.0',
      success: null,
      error: err.message
    });
  }
};

exports.toggleRegister = async (req, res) => {
  try {
    const { enabled } = req.body;
    const isEnabled = enabled === 'true';

    const { data: existingData } = await supabaseAdmin
      .from('app_settings')
      .select('*')
      .eq('key', 'registration_enabled')
      .maybeSingle();

    if (existingData) {
      await supabaseAdmin
        .from('app_settings')
        .update({ value: isEnabled.toString() })
        .eq('key', 'registration_enabled');
    } else {
      await supabaseAdmin
        .from('app_settings')
        .insert({ key: 'registration_enabled', value: isEnabled.toString() });
    }

    res.redirect('/admin?success=Registration+setting+updated');
  } catch (err) {
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};

exports.createUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    const { error } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true
    });
    if (error) throw error;
    res.redirect('/admin?success=User+created+successfully');
  } catch (err) {
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};

exports.updateUser = async (req, res) => {
  try {
    const { userId, password } = req.body;
    const { error } = await supabaseAdmin.auth.admin.updateUserById(userId, { password });
    if (error) throw error;
    res.redirect('/admin?success=Password+updated+successfully');
  } catch (err) {
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};

exports.sendNotification = async (req, res) => {
  try {
    let { audience, targetUserId, selectedUsers, title, message } = req.body;

    if (!title || !message) {
      throw new Error('Notification title and message are required');
    }

    let userIds = [];
    if (audience === 'all' || targetUserId === 'all') {
      const { data: { users }, error: listErr } = await supabaseAdmin.auth.admin.listUsers();
      if (listErr) throw listErr;
      if (users && users.length > 0) {
        userIds = users.map(u => u.id);
      }
    } else {
      if (Array.isArray(selectedUsers)) {
        userIds = selectedUsers.filter(id => typeof id === 'string' && id.trim().length > 0);
      } else if (typeof selectedUsers === 'string' && selectedUsers.trim().length > 0) {
        userIds = [selectedUsers.trim()];
      } else if (targetUserId && targetUserId !== 'all') {
        userIds = [targetUserId.trim()];
      }
    }

    if (userIds.length === 0) {
      throw new Error('Please select at least one recipient user or choose All Operators');
    }

    const notifications = userIds.map(uid => ({
      user_id: uid,
      title: title.trim(),
      message: message.trim(),
      is_read: false
    }));

    const { error: insertErr } = await supabaseAdmin.from('notifications').insert(notifications);
    if (insertErr) throw insertErr;

    const countMsg = audience === 'all' || targetUserId === 'all'
      ? 'Broadcast+sent+to+all+operators'
      : `Notification+sent+to+${userIds.length}+selected+user(s)`;
    res.redirect(`/admin?success=${countMsg}`);
  } catch (err) {
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};

// â”€â”€â”€ PRODUCTION PRODUCTS & STEPS MANAGEMENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
exports.addProductType = async (req, res) => {
  try {
    const { product_name, category, color, steps_text } = req.body;
    if (!product_name) throw new Error('Product name is required');

    // Insert Product
    const { data: product, error: pErr } = await supabaseAdmin
      .from('production_products')
      .insert([{
        name: product_name.trim(),
        category: category || 'Factory Production',
        color: color || '#2563EB'
      }])
      .select()
      .single();

    if (pErr) throw pErr;

    // Parse Steps from multiline text (e.g. Paper Cutting, Rolling, Drying)
    if (steps_text) {
      const stepLines = steps_text
        .split('\n')
        .map(s => s.trim())
        .filter(s => s.length > 0);

      const stepRows = stepLines.map((line, idx) => {
        // Support syntax like: "Paper Cutting (3%)" or just "Paper Cutting"
        let name = line;
        let tol = 5.0;
        const match = line.match(/^(.+?)\s*\(([0-9.]+)%?\)$/);
        if (match) {
          name = match[1].trim();
          tol = parseFloat(match[2]);
        }
        return {
          product_id: product.id,
          step_number: idx + 1,
          process_name: name,
          expected_tolerance_pct: tol
        };
      });

      if (stepRows.length > 0) {
        await supabaseAdmin.from('production_process_templates').insert(stepRows);
      }
    }

    res.redirect('/admin?success=Product+and+process+steps+saved');
  } catch (err) {
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};

exports.deleteProductType = async (req, res) => {
  try {
    const { product_id } = req.body;
    if (!product_id) throw new Error('Missing product ID');

    await supabaseAdmin.from('production_process_templates').delete().eq('product_id', product_id);
    await supabaseAdmin.from('production_products').delete().eq('id', product_id);

    res.redirect('/admin?success=Product+removed');
  } catch (err) {
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};

// â”€â”€â”€ FACTORY MASTER RESET & CLEAN WIPE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
exports.masterWipe = async (req, res) => {
  try {
    const { confirm_phrase, wipe_users } = req.body;

    if (confirm_phrase !== 'DELETE-ALL-DATA') {
      return res.redirect('/admin?error=Confirmation+phrase+incorrect.+Must+be+DELETE-ALL-DATA');
    }

    // 1. Wipe Child Production Logs first
    await supabaseAdmin.from('production_logs').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    // 2. Wipe Production Orders
    await supabaseAdmin.from('production_orders').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    // 3. Wipe Payroll & Attendance
    await supabaseAdmin.from('salary_payments').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    await supabaseAdmin.from('attendance').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    // 4. Wipe Employees
    await supabaseAdmin.from('employees').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    // 5. Wipe Inventory Items
    await supabaseAdmin.from('items').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    // 6. Wipe Notifications
    await supabaseAdmin.from('notifications').delete().neq('id', '00000000-0000-0000-0000-000000000000');

    // 7. Optionally Wipe Non-Admin Users
    if (wipe_users === 'true' || wipe_users === true) {
      try {
        const { data: { users } } = await supabaseAdmin.auth.admin.listUsers();
        if (users) {
          for (const u of users) {
            // Protect admin account from deletion
            if (u.email !== 'mtkv@gmail.com') {
              await supabaseAdmin.auth.admin.deleteUser(u.id);
            }
          }
        }
      } catch (uErr) {
        console.warn('Wipe users warning:', uErr.message);
      }
    }

    res.redirect('/admin?success=Factory+database+wiped+successfully!+Ready+for+client+handover.');
  } catch (err) {
    console.error('masterWipe error:', err);
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};

// ─── RELEASE APK & OTA SETTINGS ──────────────────────────────────────────────
exports.updateApkSettings = async (req, res) => {
  try {
    const { apk_download_url, apk_version } = req.body;

    if (apk_download_url) {
      const { data: existing } = await supabaseAdmin
        .from('app_settings')
        .select('*')
        .eq('key', 'apk_download_url')
        .maybeSingle();

      if (existing) {
        await supabaseAdmin
          .from('app_settings')
          .update({ value: apk_download_url.trim() })
          .eq('key', 'apk_download_url');
      } else {
        await supabaseAdmin
          .from('app_settings')
          .insert({ key: 'apk_download_url', value: apk_download_url.trim() });
      }
    }

    if (apk_version) {
      const { data: existingV } = await supabaseAdmin
        .from('app_settings')
        .select('*')
        .eq('key', 'apk_version')
        .maybeSingle();

      if (existingV) {
        await supabaseAdmin
          .from('app_settings')
          .update({ value: apk_version.trim() })
          .eq('key', 'apk_version');
      } else {
        await supabaseAdmin
          .from('app_settings')
          .insert({ key: 'apk_version', value: apk_version.trim() });
      }
    }

    res.redirect('/admin?success=Release+APK+download+URL+updated+successfully');
  } catch (err) {
    res.redirect('/admin?error=' + encodeURIComponent(err.message));
  }
};
