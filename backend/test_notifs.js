const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function test() {
  // Get all users
  const { data: { users }, error } = await supabase.auth.admin.listUsers();
  console.log("Users:", users.map(u => u.email));

  // Find user
  const user = users.find(u => u.email === 'kavyapatel3032@gmail.com');
  if (!user) return console.log("User not found");

  // Fetch notifications for this user just like the controller does
  const { data: notifs, error: notifErr } = await supabase
    .from('notifications')
    .select('*')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false });

  console.log("Notifications for user:", notifs);
}

test();
