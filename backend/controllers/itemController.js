const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Create admin client bypassing RLS using SERVICE_ROLE_KEY
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_PUBLISHABLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// Helper to get client (prefers service role key, otherwise authenticated user JWT)
const getClient = (req) => {
  if (process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY) {
    return supabaseAdmin;
  }
  if (req && req.token) {
    return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_PUBLISHABLE_KEY, {
      global: {
        headers: {
          Authorization: `Bearer ${req.token}`
        }
      },
      auth: { persistSession: false }
    });
  }
  return supabaseAdmin;
};

// Get all items
const getItems = async (req, res) => {
  try {
    const client = getClient(req);
    const { data, error } = await client
      .from('items')
      .select('*');

    if (error) throw error;
    res.status(200).json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Get single item by ID
const getItemById = async (req, res) => {
  try {
    const { id } = req.params;
    const client = getClient(req);
    const { data, error } = await client
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

// Create new item
const createItem = async (req, res) => {
  try {
    const newItem = { ...req.body };

    if (newItem.image_base64) {
      try {
        const base64Data = newItem.image_base64.replace(/^data:image\/\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const fileName = `item-${Date.now()}.jpg`;

        // Ensure bucket exists
        const { data: buckets } = await supabaseAdmin.storage.listBuckets();
        if (!buckets || !buckets.find(b => b.name === 'items')) {
          await supabaseAdmin.storage.createBucket('items', {
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png'],
            fileSizeLimit: 10485760 // 10MB
          });
        }

        const { data: uploadData, error: uploadError } = await supabaseAdmin.storage
          .from('items')
          .upload(fileName, buffer, { contentType: 'image/jpeg', upsert: true });

        if (uploadError) throw uploadError;

        const { data: publicUrlData } = supabaseAdmin.storage.from('items').getPublicUrl(fileName);
        newItem.image_url = publicUrlData.publicUrl;
      } catch (e) {
        console.error("Item image upload failed:", e);
      }
      delete newItem.image_base64; // Don't insert base64 into the DB
    }

    const client = getClient(req);
    const { data, error } = await client
      .from('items')
      .insert([newItem])
      .select();

    if (error) throw error;
    res.status(201).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Update item
const updateItem = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const client = getClient(req);
    const { data, error } = await client
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

// Delete item
const deleteItem = async (req, res) => {
  try {
    const { id } = req.params;
    
    const client = getClient(req);
    const { data, error } = await client
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

module.exports = {
  getItems,
  getItemById,
  createItem,
  updateItem,
  deleteItem
};
