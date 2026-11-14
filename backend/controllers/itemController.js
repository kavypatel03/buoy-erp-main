const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY
  || process.env.SUPABASE_SECRET_KEY;
const ANON_KEY = process.env.SUPABASE_PUBLISHABLE_KEY
  || process.env.SUPABASE_ANON_KEY
  || process.env.SUPABASE_KEY;

// Admin client — bypasses ALL RLS (requires service_role key in Vercel env vars)
const supabaseAdmin = SERVICE_ROLE_KEY
  ? createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false }
    })
  : null;

/**
 * Returns the best available Supabase client for this request:
 *  1. supabaseAdmin  — if service_role key is available (bypasses RLS entirely)
 *  2. user-scoped client — built from the validated JWT (Supabase honours the
 *     user's own RLS policies, so make sure the INSERT/UPDATE/DELETE policies
 *     exist for authenticated users)
 *  3. anon client fallback
 */
const getClient = (req) => {
  // Best option: service role bypasses RLS
  if (supabaseAdmin) return supabaseAdmin;

  // Extract auth token from req.token or Authorization header
  const authHeader = req?.headers?.authorization;
  const token = req?.token || (authHeader?.startsWith('Bearer ') ? authHeader.split(' ')[1] : null);

  // Second option: authenticated user client using their JWT
  if (token && ANON_KEY) {
    return createClient(SUPABASE_URL, ANON_KEY, {
      global: {
        headers: { Authorization: `Bearer ${token}` }
      },
      auth: { persistSession: false, autoRefreshToken: false }
    });
  }

  // Last resort – anon (will fail if RLS active)
  return createClient(SUPABASE_URL, ANON_KEY || '', {
    auth: { persistSession: false }
  });
};

// ─── GET all items ───────────────────────────────────────────────────────────
const getItems = async (req, res) => {
  try {
    const { data, error } = await getClient(req).from('items').select('*');
    if (error) throw error;
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ─── GET single item ─────────────────────────────────────────────────────────
const getItemById = async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await getClient(req)
      .from('items')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Item not found' });
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ─── CREATE item ─────────────────────────────────────────────────────────────
const createItem = async (req, res) => {
  try {
    const newItem = { ...req.body };

    // Handle optional base64 image upload
    if (newItem.image_base64) {
      try {
        const adminClient = supabaseAdmin || getClient(req);
        const base64Data = newItem.image_base64.replace(/^data:image\/\w+;base64,/, '');
        const buffer = Buffer.from(base64Data, 'base64');
        const fileName = `item-${Date.now()}.jpg`;

        // Ensure bucket exists
        const { data: buckets } = await adminClient.storage.listBuckets();
        if (!buckets || !buckets.find((b) => b.name === 'items')) {
          await adminClient.storage.createBucket('items', {
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png'],
            fileSizeLimit: 10485760 // 10 MB
          });
        }

        const { error: uploadError } = await adminClient.storage
          .from('items')
          .upload(fileName, buffer, { contentType: 'image/jpeg', upsert: true });

        if (uploadError) throw uploadError;

        const { data: publicUrlData } = adminClient.storage
          .from('items')
          .getPublicUrl(fileName);
        newItem.image_url = publicUrlData.publicUrl;
      } catch (e) {
        console.error('Item image upload failed:', e.message);
        // Non-fatal — continue without image
      }
      delete newItem.image_base64;
    }

    // Attach user identifiers so RLS owner policies pass
    const userId = req.user?.id;
    if (userId) {
      if (!newItem.owner_id) newItem.owner_id = userId;
      if (!newItem.user_id) newItem.user_id = userId;
    }

    let result = await getClient(req)
      .from('items')
      .insert([newItem])
      .select();

    // If table doesn't have owner_id or user_id columns, strip and retry
    if (result.error && result.error.message && result.error.message.includes('does not exist')) {
      const match = result.error.message.match(/column "([^"]+)" of relation/);
      if (match && match[1]) {
        delete newItem[match[1]];
        result = await getClient(req).from('items').insert([newItem]).select();
      }
      if (result.error && result.error.message && result.error.message.includes('does not exist')) {
        const match2 = result.error.message.match(/column "([^"]+)" of relation/);
        if (match2 && match2[1]) {
          delete newItem[match2[1]];
          result = await getClient(req).from('items').insert([newItem]).select();
        }
      }
    }

    if (result.error) throw result.error;
    res.status(201).json(result.data[0]);
  } catch (error) {
    console.error('createItem error:', error.message);
    res.status(500).json({ error: error.message });
  }
};

// ─── UPDATE item ─────────────────────────────────────────────────────────────
const updateItem = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const { data, error } = await getClient(req)
      .from('items')
      .update(updates)
      .eq('id', id)
      .select();

    if (error) throw error;
    res.status(200).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ─── DELETE item ─────────────────────────────────────────────────────────────
const deleteItem = async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await getClient(req)
      .from('items')
      .delete()
      .eq('id', id)
      .select();

    if (error) throw error;
    res.status(200).json({ message: 'Item deleted successfully', data: data[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { getItems, getItemById, createItem, updateItem, deleteItem };
