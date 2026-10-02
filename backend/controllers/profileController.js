const { createClient } = require('@supabase/supabase-js');
const supabaseConfig = require('../config/supabase');

// Helper to create an authenticated client for the current request
const getAuthClient = (req) => {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_PUBLISHABLE_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${req.token}`
      }
    },
    auth: { persistSession: false }
  });
};

const getProfile = async (req, res) => {
  try {
    const supabaseClient = getAuthClient(req);
    const { data, error } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .single();
    
    // PGRST116 means 0 rows found (which is fine if they haven't saved a profile yet)
    if (error && error.code !== 'PGRST116') throw error;
    
    res.status(200).json({ ...(data || {}), email: req.user.email });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { first_name, middle_name, surname, mobile, occupation } = req.body;
    
    // Upsert (Insert or Update) profile data
    const supabaseClient = getAuthClient(req);
    const { data, error } = await supabaseClient
      .from('profiles')
      .upsert({
        id: req.user.id, // linked to the auth.users ID
        first_name,
        middle_name,
        surname,
        mobile,
        occupation,
        updated_at: new Date()
      }, { onConflict: 'id' })
      .select();

    if (error) throw error;
    res.status(200).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { getProfile, updateProfile };
