const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const requireAuth = require('../middleware/authMiddleware');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/registration-status', authController.getRegistrationStatus);

// Protected routes
router.get('/profile', requireAuth, authController.getProfile);

// Device FCM registration (supports both authenticated users and initial device registrations)
router.post('/fcm-token', (req, res, next) => {
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    return requireAuth(req, res, next);
  }
  next();
}, authController.updateFcmToken);

module.exports = router;
