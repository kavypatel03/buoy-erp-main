const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const requireAuth = require('../middleware/authMiddleware');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/registration-status', authController.getRegistrationStatus);

// Protected route (requires valid JWT token)
router.get('/profile', requireAuth, authController.getProfile);
router.post('/fcm-token', requireAuth, authController.updateFcmToken);

module.exports = router;
