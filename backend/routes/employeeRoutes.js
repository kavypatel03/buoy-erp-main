const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');

router.get('/', employeeController.getEmployees);
router.post('/', employeeController.createEmployee);
router.put('/:id', employeeController.editEmployee);
router.post('/:id/pay-salary', employeeController.paySalary);
router.post('/:id/clock-in', employeeController.clockIn);
router.post('/:id/clock-out', employeeController.clockOut);
router.delete('/:id', employeeController.deleteEmployee);

module.exports = router;
