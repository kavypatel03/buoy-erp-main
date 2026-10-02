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

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_PUBLISHABLE_KEY,
  { auth: { persistSession: false } }
);

const updateProfile = async (req, res) => {
  try {
    const { first_name, middle_name, surname, mobile, occupation, avatar_base64 } = req.body;
    
    let avatar_url = undefined;

    if (avatar_base64) {
      try {
        const base64Data = avatar_base64.replace(/^data:image\/\w+;base64,/, "");
        const buffer = Buffer.from(base64Data, 'base64');
        const fileName = `${req.user.id}-${Date.now()}.jpg`;

        // Ensure bucket exists
        const { data: buckets } = await supabaseAdmin.storage.listBuckets();
        if (!buckets || !buckets.find(b => b.name === 'avatars')) {
          await supabaseAdmin.storage.createBucket('avatars', {
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png'],
            fileSizeLimit: 10485760 // 10MB
          });
        }

        // Upload using admin client to bypass storage RLS
        const { data: uploadData, error: uploadError } = await supabaseAdmin.storage
          .from('avatars')
          .upload(fileName, buffer, {
            contentType: 'image/jpeg',
            upsert: true
          });

        if (uploadError) throw uploadError;

        const { data: publicUrlData } = supabaseAdmin.storage
          .from('avatars')
          .getPublicUrl(fileName);

        avatar_url = publicUrlData.publicUrl;
      } catch (e) {
        console.error("Avatar upload failed:", e);
      }
    }

    const updates = {
      id: req.user.id,
      first_name,
      middle_name,
      surname,
      mobile,
      occupation,
      updated_at: new Date()
    };
    
    if (avatar_url) {
      updates.avatar_url = avatar_url;
    }

    // Upsert (Insert or Update) profile data
    const supabaseClient = getAuthClient(req);
    const { data, error } = await supabaseClient
      .from('profiles')
      .upsert(updates, { onConflict: 'id' })
      .select();

    if (error) throw error;
    res.status(200).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = { getProfile, updateProfile };
