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
      .maybeSingle();
      
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
    
    const { data: existingData, error: fetchError } = await supabaseAdmin
      .from('app_settings')
      .select('*')
      .eq('key', 'registration_enabled')
      .maybeSingle();

    if (fetchError) throw fetchError;

    if (existingData) {
      const { error: updateError } = await supabaseAdmin
        .from('app_settings')
        .update({ value: isEnabled.toString() })
        .eq('key', 'registration_enabled');
      if (updateError) throw updateError;
    } else {
      const { error: insertError } = await supabaseAdmin
        .from('app_settings')
        .insert({ key: 'registration_enabled', value: isEnabled.toString() });
      if (insertError) throw insertError;
    }
    
    res.redirect('/admin');
  } catch (err) {
    console.error("Toggle Error:", err);
    res.render('dashboard', { users: [], regEnabled: true, error: "Failed to toggle registration: " + err.message });
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

const admin = require('firebase-admin');

try {
  let cert;
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    cert = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } else {
    cert = require('../firebase-adminsdk.json');
  }
  admin.initializeApp({
    credential: admin.credential.cert(cert)
  });
} catch (e) {
  console.warn("Firebase Admin SDK not initialized. FCM will not be sent.", e.message);
}

exports.sendNotification = async (req, res) => {
  try {
    const { targetUserId, title, message } = req.body;
    
    let targetUsers = [];
    if (targetUserId === 'all') {
      const { data: { users }, error: usersError } = await supabaseAdmin.auth.admin.listUsers();
      if (usersError) throw usersError;
      targetUsers = users;
      
      const notifications = users.map(u => ({
        user_id: u.id,
        title,
        message,
        is_read: false
      }));
      await supabaseAdmin.from('notifications').insert(notifications);
    } else {
      targetUsers = [{ id: targetUserId }];
      await supabaseAdmin.from('notifications').insert({
        user_id: targetUserId,
        title,
        message,
        is_read: false
      });
    }

    // Try to send FCM pushes
    if (admin.apps.length > 0) {
      for (const u of targetUsers) {
        // Get the FCM token for this user
        const { data: tokenData } = await supabaseAdmin
          .from('user_fcm_tokens')
          .select('token')
          .eq('user_id', u.id)
          .single();
          
        if (tokenData && tokenData.token) {
          try {
            await admin.messaging().send({
              token: tokenData.token,
              notification: { title, body: message }
            });
            console.log(`Pushed FCM to ${u.id}`);
          } catch (e) {
            console.error(`Failed to push FCM to ${u.id}:`, e);
          }
        }
      }
    }
    
    res.redirect('/admin');
  } catch (err) {
    console.error(err);
    res.redirect('/admin');
  }
};
