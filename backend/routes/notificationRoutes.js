const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');

router.get('/', notificationController.getNotifications);
router.post('/:id/read', notificationController.markAsRead);
router.delete('/all', notificationController.clearAll);
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;
