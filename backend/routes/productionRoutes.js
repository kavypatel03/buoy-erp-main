const express = require('express');
const router = express.Router();
const productionController = require('../controllers/productionController');

// All routes are prefixed with /api/production and protected by authMiddleware

// Production Orders
router.get('/orders', productionController.getOrders);
router.post('/orders', productionController.createOrder);
router.post('/orders/:id/complete', productionController.completeOrder);

// Production Logs (Processes)
router.post('/orders/:id/log', productionController.addProcessLog);

// Wastage Report
router.get('/wastage-report', productionController.getWastageReport);

module.exports = router;
