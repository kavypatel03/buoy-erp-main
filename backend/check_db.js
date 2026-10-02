const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkNotifications() {
  console.log("Checking notifications...");
  const { data, error } = await supabase.from('notifications').select('*');
  if (error) {
    console.error("Error fetching notifications:", error);
  } else {
    console.log("Notifications in DB:", data);
  }
}

checkNotifications();
