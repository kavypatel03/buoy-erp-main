const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

const requireAdmin = (req, res, next) => {
  if (req.signedCookies.admin_auth === 'true') {
    next();
  } else {
    res.redirect('/admin/login');
  }
};

router.get('/login', adminController.getLogin);
router.post('/login', adminController.postLogin);
router.get('/logout', adminController.logout);

router.get('/', requireAdmin, adminController.getDashboard);
router.post('/toggle-register', requireAdmin, adminController.toggleRegister);
router.post('/create-user', requireAdmin, adminController.createUser);
router.post('/update-user', requireAdmin, adminController.updateUser);
router.post('/send-notification', requireAdmin, adminController.sendNotification);

module.exports = router;
