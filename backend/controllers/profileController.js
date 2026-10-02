const supabase = require('../config/supabase');

const getProfile = async (req, res) => {
  try {
    const { data, error } = await supabase
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
    const { data, error } = await supabase
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
