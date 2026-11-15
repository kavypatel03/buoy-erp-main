const { initializeApp, cert, getApps, deleteApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const supabaseAdmin = require('../config/supabase');
const fs = require('fs');
const path = require('path');

let isInitialized = false;
let initError = null;

/**
 * Parses a service account credential from string, base64, or object.
 */
function parseServiceAccount(input) {
  if (!input) return null;
  if (typeof input === 'object') return input;
  try {
    const trimmed = input.trim();
    if (trimmed.startsWith('{')) {
      return JSON.parse(trimmed);
    }
    // Try base64 decoding
    const decoded = Buffer.from(trimmed, 'base64').toString('utf8');
    return JSON.parse(decoded);
  } catch (err) {
    return null;
  }
}

/**
 * Initializes Firebase Admin SDK from:
 * 1. Explicit credentials passed
 * 2. process.env.FIREBASE_SERVICE_ACCOUNT (JSON string or base64)
 * 3. File in backend/ or root matching *firebase-adminsdk*.json
 * 4. Stored in Supabase app_settings (key: 'firebase_service_account')
 */
async function initFirebase(customCreds = null) {
  try {
    const activeApps = getApps();
    if (activeApps && activeApps.length > 0) {
      isInitialized = true;
      initError = null;
      return true;
    }
  } catch (e) {
    // getApps check error
  }

  let creds = null;

  if (customCreds) {
    creds = parseServiceAccount(customCreds);
  }

  // 1. Check environment variable
  if (!creds && process.env.FIREBASE_SERVICE_ACCOUNT) {
    creds = parseServiceAccount(process.env.FIREBASE_SERVICE_ACCOUNT);
  }

  // 2. Check local file in backend or project root
  if (!creds) {
    const candidates = [
      path.join(__dirname, '../firebase-service-account.json'),
      path.join(__dirname, '../../buoy-erp-firebase-adminsdk-fbsvc-1eb002d928.json'),
      path.join(process.cwd(), 'buoy-erp-firebase-adminsdk-fbsvc-1eb002d928.json'),
      path.join(process.cwd(), 'backend/firebase-service-account.json')
    ];

    for (const p of candidates) {
      if (fs.existsSync(p)) {
        try {
          creds = JSON.parse(fs.readFileSync(p, 'utf8'));
          if (creds && creds.project_id) break;
        } catch (_) {}
      }
    }
  }

  // 3. Check Supabase app_settings
  if (!creds) {
    try {
      const { data, error } = await supabaseAdmin
        .from('app_settings')
        .select('value')
        .eq('key', 'firebase_service_account')
        .maybeSingle();

      if (!error && data && data.value) {
        creds = parseServiceAccount(data.value);
      }
    } catch (e) {
      // Supabase table offline
    }
  }

  if (creds && creds.project_id && (creds.private_key || creds.client_email)) {
    try {
      initializeApp({
        credential: cert(creds),
        projectId: creds.project_id
      });
      isInitialized = true;
      initError = null;
      console.log(`✅ Firebase Admin SDK connected to project: ${creds.project_id}`);
      return true;
    } catch (err) {
      isInitialized = false;
      initError = err.message;
      console.error('❌ Firebase Admin initialization error:', err.message);
      return false;
    }
  }

  isInitialized = false;
  initError = 'No Firebase service account credentials found.';
  return false;
}

// Auto-run on module import
initFirebase().catch(() => {});

/**
 * Returns current status of push notifications
 */
async function getPushStats() {
  if (!isInitialized) {
    await initFirebase();
  }

  let totalDevices = 0;
  let activeUsersWithDevices = 0;
  let tableExists = true;

  try {
    const { data, error } = await supabaseAdmin
      .from('user_fcm_tokens')
      .select('user_id, token');

    if (error) {
      tableExists = false;
    } else if (data) {
      totalDevices = data.length;
      activeUsersWithDevices = new Set(data.map(d => d.user_id)).size;
    }
  } catch (e) {
    tableExists = false;
  }

  return {
    isConfigured: isInitialized,
    initError: initError,
    tableExists: tableExists,
    totalDevices: totalDevices,
    activeUsersWithDevices: activeUsersWithDevices
  };
}

/**
 * Saves service account credentials to app_settings and re-initializes
 */
async function saveCredentials(jsonString) {
  const parsed = parseServiceAccount(jsonString);
  if (!parsed || !parsed.project_id || !parsed.private_key) {
    throw new Error('Invalid Firebase service account JSON. Ensure it has "project_id" and "private_key".');
  }

  // Persist to Supabase app_settings so it works across all Vercel instances instantly
  await supabaseAdmin
    .from('app_settings')
    .upsert({
      key: 'firebase_service_account',
      value: JSON.stringify(parsed),
      updated_at: new Date().toISOString()
    }, { onConflict: 'key' });

  // Delete existing Firebase apps before re-initializing
  try {
    const activeApps = getApps();
    if (activeApps && activeApps.length > 0) {
      await Promise.all(activeApps.map(app => deleteApp(app)));
    }
  } catch (e) {
    console.warn('Error clearing active Firebase apps:', e.message);
  }

  isInitialized = false;
  return await initFirebase(parsed);
}

/**
 * Sends a real background push notification to target user(s) via FCM.
 * Will appear in Android status bar & lock screen even when app is CLOSED!
 */
async function sendPushNotification({ userIds = 'all', title, body, data = {} }) {
  if (!isInitialized) {
    await initFirebase();
  }

  if (!isInitialized) {
    console.warn(`[PushNotification] Skipped FCM push (not configured): "${title}"`);
    return {
      sent: false,
      reason: 'FCM not configured. Set Firebase Service Account in Admin Console.'
    };
  }

  try {
    let query = supabaseAdmin.from('user_fcm_tokens').select('token, user_id');

    if (userIds !== 'all' && Array.isArray(userIds) && userIds.length > 0) {
      query = query.in('user_id', userIds);
    } else if (typeof userIds === 'string' && userIds !== 'all') {
      query = query.eq('user_id', userIds);
    }

    const { data: tokenRows, error: tokenErr } = await query;

    if (tokenErr) {
      console.error('[PushNotification] Error fetching user tokens:', tokenErr.message);
      return { sent: false, error: tokenErr.message };
    }

    if (!tokenRows || tokenRows.length === 0) {
      console.log('[PushNotification] No registered device tokens found for target user(s).');
      return { sent: false, count: 0, reason: 'No registered device tokens' };
    }

    // Extract unique non-empty tokens
    const tokens = Array.from(new Set(tokenRows.map(r => r.token).filter(Boolean)));
    if (tokens.length === 0) return { sent: false, count: 0 };

    console.log(`[PushNotification] Dispatching FCM push to ${tokens.length} device(s)...`);

    // Prepare message payload with HIGH priority and channel ID for heads-up display
    const payload = {
      notification: {
        title: title || 'Buoy ERP Alert',
        body: body || ''
      },
      data: {
        title: title || 'Buoy ERP Alert',
        body: body || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        timestamp: Date.now().toString(),
        ...data
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'buoy_erp_notifications',
          priority: 'max',
          defaultSound: true,
          defaultVibrateTimings: true,
          visibility: 'public',
          icon: '@mipmap/launcher_icon'
        }
      },
      tokens: tokens
    };

    const messaging = getMessaging();
    const response = await messaging.sendEachForMulticast(payload);
    console.log(`[PushNotification] Result: ${response.successCount} succeeded, ${response.failureCount} failed.`);

    // Automatically prune dead / unregistered tokens
    if (response.failureCount > 0) {
      const deadTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errCode = resp.error?.code;
          if (
            errCode === 'messaging/registration-token-not-registered' ||
            errCode === 'messaging/invalid-registration-token'
          ) {
            deadTokens.push(tokens[idx]);
          }
        }
      });

      if (deadTokens.length > 0) {
        console.log(`[PushNotification] Pruning ${deadTokens.length} expired device token(s)...`);
        await supabaseAdmin
          .from('user_fcm_tokens')
          .delete()
          .in('token', deadTokens);
      }
    }

    return {
      sent: true,
      totalDevices: tokens.length,
      successCount: response.successCount,
      failureCount: response.failureCount
    };
  } catch (err) {
    console.error('[PushNotification] Unexpected error:', err);
    return { sent: false, error: err.message };
  }
}

module.exports = {
  initFirebase,
  getPushStats,
  saveCredentials,
  sendPushNotification
};
