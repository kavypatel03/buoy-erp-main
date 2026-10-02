const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function injectNotifs() {
  const { data: { users } } = await supabase.auth.admin.listUsers();
  
  for (const user of users) {
    console.log(`Injecting for ${user.email} (${user.id})`);
    await supabase.from('notifications').insert([
      {
        user_id: user.id,
        title: 'System Alert: Testing',
        message: 'This is a test notification injected into DB directly.',
        is_read: false
      }
    ]);
  }
  console.log("Done");
}

injectNotifs();
