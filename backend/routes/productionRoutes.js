const express = require('express');
const router = express.Router();
const productionController = require('../controllers/productionController');

// All routes are prefixed with /api/production and protected by authMiddleware

// Product Types & Recipes
router.get('/product-types', productionController.getProductTypes);
router.post('/product-types', productionController.createProductType);
router.delete('/product-types/:id', productionController.deleteProductType);

// Production Orders
router.get('/orders', productionController.getOrders);
router.post('/orders', productionController.createOrder);
router.post('/orders/:id/complete', productionController.completeOrder);

// Production Logs (Processes)
router.post('/orders/:id/log', productionController.addProcessLog);
router.put('/logs/:logId', productionController.updateProcessLog);

// Wastage Report & ML Monitoring
router.get('/wastage-report', productionController.getWastageReport);
router.get('/wastage-report/export/excel', productionController.exportWastageExcel);
router.get('/wastage-report/export/pdf', productionController.exportWastagePdf);

module.exports = router;
