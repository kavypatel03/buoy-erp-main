require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const path = require('path');

// Import routes and middleware
const itemRoutes = require('./routes/itemRoutes');
const authRoutes = require('./routes/authRoutes');
const profileRoutes = require('./routes/profileRoutes');
const adminRoutes = require('./routes/adminRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const productionRoutes = require('./routes/productionRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const requireAuth = require('./middleware/authMiddleware');
const { supabaseAdmin } = require('./config/supabase');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
app.use(cookieParser('buoy-erp-secret-key'));

// View Engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Completely disable and block /admin route on the frontend domain (buoy-erp.vercel.app)
// The admin console is isolated and only accessible via https://buoy-erp-main.vercel.app/admin
app.use('/admin', (req, res, next) => {
  const host = req.headers['x-forwarded-host'] || req.headers.host || '';
  if (host.includes('buoy-erp.vercel.app') && !host.includes('buoy-erp-main')) {
    return res.status(404).send('Cannot GET /admin');
  }
  next();
});

// Root route on backend redirects directly to the Admin Portal
app.get('/', (req, res) => {
  res.redirect('/admin');
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', requireAuth, profileRoutes);
app.use('/api/items', requireAuth, itemRoutes);
app.use('/api/notifications', requireAuth, notificationRoutes);
app.use('/api/employees', requireAuth, employeeRoutes);
app.use('/api/production', requireAuth, productionRoutes);
app.use('/api/dashboard', requireAuth, dashboardRoutes);
app.use('/admin', adminRoutes);

// Basic health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Backend is running' });
});

// App version & In-App Auto-Update endpoint
app.get('/api/app/version', async (req, res) => {
  try {
    let latestVersion = '1.0.0';
    let downloadUrl = 'https://github.com/kavypatel03/buoy-erp-main/raw/main/web/download/buoy-erp.apk';

    const { data } = await supabaseAdmin
      .from('app_settings')
      .select('*')
      .in('key', ['apk_download_url', 'apk_version']);

    if (data && data.length > 0) {
      const u = data.find(r => r.key === 'apk_download_url');
      const v = data.find(r => r.key === 'apk_version');
      if (u?.value) downloadUrl = u.value;
      if (v?.value) latestVersion = v.value;
    }

    res.status(200).json({
      latestVersion,
      buildNumber: 1,
      releaseDate: new Date().toISOString(),
      downloadUrl,
      releaseNotes: 'Continuous live over-the-air updates enabled. Latest factory release.',
      forceUpdate: false
    });
  } catch (_) {
    res.status(200).json({
      latestVersion: '1.0.0',
      buildNumber: 1,
      downloadUrl: 'https://github.com/kavypatel03/buoy-erp-main/raw/main/web/download/buoy-erp.apk',
      releaseNotes: 'Production release',
      forceUpdate: false
    });
  }
});

// Dynamic APK Download Handler: always routes user to the latest updated release APK
app.get(['/download/buoy-erp.apk', '/api/app/download'], async (req, res) => {
  try {
    const { data } = await supabaseAdmin
      .from('app_settings')
      .select('value')
      .eq('key', 'apk_download_url')
      .maybeSingle();

    if (data && data.value && data.value.startsWith('http')) {
      return res.redirect(302, data.value);
    }

    // Default: redirect directly to the verified raw GitHub APK release binary
    return res.redirect(302, 'https://github.com/kavypatel03/buoy-erp-main/raw/main/web/download/buoy-erp.apk');
  } catch (err) {
    return res.redirect(302, 'https://github.com/kavypatel03/buoy-erp-main/raw/main/web/download/buoy-erp.apk');
  }
});

// Start the server (Only if not running in a serverless environment like Vercel)
if (process.env.NODE_ENV !== 'production') {
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}

module.exports = app;
