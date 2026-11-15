const { createClient } = require('@supabase/supabase-js');
const supabase = require('../config/supabase');

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL || 'https://placeholder.supabase.co',
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY || 'placeholder-key',
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
    const { fcmToken, deviceType, userId: bodyUserId } = req.body;
    const userId = req.user?.id || bodyUserId || 'device_anonymous';
    
    if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
      return res.status(400).json({ error: 'Valid fcmToken is required' });
    }

    // Upsert into user_fcm_tokens (supports multiple devices per user or token updates)
    const { error } = await supabaseAdmin
      .from('user_fcm_tokens')
      .upsert({
        user_id: userId,
        token: fcmToken.trim(),
        device_type: deviceType || 'android',
        updated_at: new Date().toISOString()
      }, { onConflict: 'token' });
      
    if (error) {
      // If schema uses onConflict user_id, retry
      const { error: err2 } = await supabaseAdmin
        .from('user_fcm_tokens')
        .upsert({
          user_id: userId,
          token: fcmToken.trim(),
          device_type: deviceType || 'android',
          updated_at: new Date().toISOString()
        }, { onConflict: 'user_id' });
      if (err2) {
        console.warn('user_fcm_tokens notice:', err2.message);
      }
    }
    
    res.status(200).json({ success: true, message: 'FCM device token registered' });
  } catch (error) {
    console.error('updateFcmToken error:', error);
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  getRegistrationStatus,
  updateFcmToken
};
