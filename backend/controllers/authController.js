const { createClient } = require('@supabase/supabase-js');
const supabase = require('../config/supabase');

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

const register = async (req, res) => {
  try {
    const { email, password, ...metadata } = req.body;
    
    // Check if registration is enabled
    const { data: settingsData, error: settingsError } = await supabaseAdmin
      .from('app_settings')
      .select('value')
      .eq('key', 'registration_enabled')
      .maybeSingle();
      
    if (settingsData && (settingsData.value === 'false' || settingsData.value === false)) {
      return res.status(403).json({ error: 'Registration is currently disabled by the administrator' });
    }
    
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata // Pass any extra data like name, role, etc.
      }
    });

    if (error) throw error;
    res.status(201).json({ message: 'Registration successful', user: data.user, session: data.session });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;
    res.status(200).json({ message: 'Login successful', user: data.user, session: data.session });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
};

const getProfile = async (req, res) => {
  // req.user is set by the authMiddleware
  res.status(200).json({ user: req.user });
};

const getRegistrationStatus = async (req, res) => {
  try {
    const { data: settingsData, error } = await supabaseAdmin
      .from('app_settings')
      .select('value')
      .eq('key', 'registration_enabled')
      .maybeSingle();

    let isEnabled = true; // default
    if (settingsData && (settingsData.value === 'false' || settingsData.value === false)) {
      isEnabled = false;
    }
    
    res.status(200).json({ enabled: isEnabled });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user.id;
    
    const { error } = await supabase
      .from('user_fcm_tokens')
      .upsert({ user_id: userId, token: fcmToken }, { onConflict: 'user_id' });
      
    if (error) throw error;
    res.status(200).json({ message: 'Token updated' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  getRegistrationStatus,
  updateFcmToken
};
