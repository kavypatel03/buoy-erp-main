const { createClient } = require('@supabase/supabase-js');
const supabaseConfig = require('../config/supabase');

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

exports.getNotifications = async (req, res) => {
  try {
    const supabaseClient = getAuthClient(req);
    const { data, error } = await supabaseClient
      .from('notifications')
      .select('*')
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false });

    if (error) throw error;
    res.status(200).json({ notifications: data });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const supabaseClient = getAuthClient(req);
    
    const { data, error } = await supabaseClient
      .from('notifications')
      .update({ is_read: true })
      .eq('id', id)
      .eq('user_id', req.user.id);

    if (error) throw error;
    res.status(200).json({ message: 'Marked as read' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
