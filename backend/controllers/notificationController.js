const { createClient } = require('@supabase/supabase-js');
const supabaseConfig = require('../config/supabase');

// Use the main supabase config which should use the service role key if available, 
// or we can just use the admin client from adminController if needed.
// Actually, let's create a direct admin client here so we don't hit RLS issues
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_PUBLISHABLE_KEY,
  { auth: { persistSession: false } }
);

exports.getNotifications = async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
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
    
    const { data, error } = await supabaseAdmin
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
exports.clearAll = async (req, res) => {
  try {
    const { error } = await supabaseAdmin
      .from('notifications')
      .delete()
      .eq('user_id', req.user.id);
      
    if (error) throw error;
    res.status(200).json({ message: 'All notifications cleared' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const { error } = await supabaseAdmin
      .from('notifications')
      .delete()
      .eq('id', id)
      .eq('user_id', req.user.id);

    if (error) throw error;
    res.status(200).json({ message: 'Notification deleted' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
