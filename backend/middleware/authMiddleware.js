const supabase = require('../config/supabase');

const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const token = authHeader.split(' ')[1];
    
    // Validate the JWT against Supabase
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error) throw error;
    if (!user) throw new Error('User not found');
    
    // Attach user data and token to request object
    req.user = user;
    req.token = token;
    next();
  } catch (error) {
    return res.status(401).json({ error: error.message || 'Unauthorized access' });
  }
};

module.exports = requireAuth;
