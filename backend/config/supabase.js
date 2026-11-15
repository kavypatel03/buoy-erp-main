require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL || 'https://placeholder.supabase.co';
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY;
const anonKey = process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_KEY;

// Admin client using service_role key if available to bypass RLS for server-side trusted operations
const supabaseAdmin = createClient(
  supabaseUrl,
  serviceRoleKey || anonKey || 'placeholder-key',
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false
    }
  }
);

/**
 * Returns the best available Supabase client for global factory operations:
 * 1. If serviceRoleKey is available, supabaseAdmin bypasses RLS completely.
 * 2. If token is in request, forward Bearer token with anonKey so Supabase validates auth.
 * 3. Fallback to supabaseAdmin / anon.
 */
const getClient = (req) => {
  if (serviceRoleKey) return supabaseAdmin;

  const authHeader = req?.headers?.authorization;
  const token = req?.token || (authHeader?.startsWith('Bearer ') ? authHeader.split(' ')[1] : null);

  if (token && anonKey) {
    return createClient(supabaseUrl, anonKey, {
      global: {
        headers: { Authorization: `Bearer ${token}` }
      },
      auth: { persistSession: false, autoRefreshToken: false }
    });
  }

  return supabaseAdmin;
};

module.exports = supabaseAdmin;
module.exports.supabase = supabaseAdmin;
module.exports.supabaseAdmin = supabaseAdmin;
module.exports.getClient = getClient;
