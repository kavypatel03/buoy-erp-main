const supabaseConfig = require('../config/supabase');
const { createClient } = require('@supabase/supabase-js');

// Create admin client bypassing RLS using SERVICE_ROLE_KEY if available
// Without this, the admin cannot list or manage other users.
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_PUBLISHABLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

exports.getLogin = (req, res) => {
  res.render('login', { error: null });
};

exports.postLogin = (req, res) => {
  const { email, password } = req.body;
  
  if (email === 'mtkv@gmail.com' && password === 'mtkv2004@2005') {
    res.cookie('admin_auth', 'true', { signed: true, httpOnly: true });
    res.redirect('/admin');
  } else {
    res.render('login', { error: 'Invalid admin credentials' });
  }
};

exports.logout = (req, res) => {
  res.clearCookie('admin_auth');
  res.redirect('/admin/login');
};

exports.getDashboard = async (req, res) => {
  try {
    if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
      return res.render('dashboard', { 
        users: [], 
        regEnabled: true,
        error: "ERROR: You must add SUPABASE_SERVICE_ROLE_KEY to your .env file to manage users!" 
      });
    }

    // Fetch users using admin API
    const { data: { users }, error: usersError } = await supabaseAdmin.auth.admin.listUsers();
    
    if (usersError) throw usersError;

    // Fetch registration setting
    let regEnabled = true;
    const { data: settingsData, error: settingsError } = await supabaseAdmin
      .from('app_settings')
      .select('value')
      .eq('key', 'registration_enabled')
      .single();
      
    if (!settingsError && settingsData) {
      regEnabled = settingsData.value === 'true' || settingsData.value === true;
    }

    res.render('dashboard', { users: users || [], regEnabled, error: null });
  } catch (err) {
    console.error(err);
    res.render('dashboard', { users: [], regEnabled: true, error: err.message });
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
    
    res.redirect('/admin');
  } catch (err) {
    res.redirect('/admin');
  }
};

exports.createUser = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true
    });
    
    if (error) throw error;
    
    // Also create empty profile
    await supabaseAdmin.from('profiles').insert({ id: data.user.id });
    
    res.redirect('/admin');
  } catch (err) {
    console.error(err);
    res.redirect('/admin');
  }
};

exports.updateUser = async (req, res) => {
  try {
    const { userId, email, password } = req.body;
    
    const updates = {};
    if (email) updates.email = email;
    if (password) updates.password = password;
    
    const { data, error } = await supabaseAdmin.auth.admin.updateUserById(userId, updates);
    if (error) throw error;
    
    res.redirect('/admin');
  } catch (err) {
    console.error(err);
    res.redirect('/admin');
  }
};

exports.sendNotification = async (req, res) => {
  try {
    const { targetUserId, title, message } = req.body;
    
    if (targetUserId === 'all') {
      // Fetch all users to send to everyone
      const { data: { users }, error: usersError } = await supabaseAdmin.auth.admin.listUsers();
      if (usersError) throw usersError;
      
      const notifications = users.map(u => ({
        user_id: u.id,
        title,
        message,
        is_read: false
      }));
      
      await supabaseAdmin.from('notifications').insert(notifications);
    } else {
      // Send to specific user
      await supabaseAdmin.from('notifications').insert({
        user_id: targetUserId,
        title,
        message,
        is_read: false
      });
    }
    
    res.redirect('/admin');
  } catch (err) {
    console.error(err);
    res.redirect('/admin');
  }
};
