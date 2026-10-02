const supabase = require('../config/supabase');

const register = async (req, res) => {
  try {
    const { email, password, ...metadata } = req.body;
    
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: metadata // Pass any extra data like name, role, etc.
      }
    });

    if (error) throw error;
    res.status(201).json({ message: 'Registration successful', user: data.user, session: data.session });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;
    res.status(200).json({ message: 'Login successful', user: data.user, session: data.session });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
};

const getProfile = async (req, res) => {
  // req.user is set by the authMiddleware
  res.status(200).json({ user: req.user });
};

module.exports = {
  register,
  login,
  getProfile
};
