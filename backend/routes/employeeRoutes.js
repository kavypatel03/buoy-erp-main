const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');

router.get('/', employeeController.getEmployees);
router.post('/', employeeController.createEmployee);
router.post('/:id/clock-in', employeeController.clockIn);
router.post('/:id/clock-out', employeeController.clockOut);

module.exports = router;
