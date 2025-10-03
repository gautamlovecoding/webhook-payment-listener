const express = require('express');
const router = express.Router();

const { 
  getPaymentEvents, 
  getPaymentDetails, 
  getAllPayments 
} = require('../controllers/paymentsController');
const { 
  paymentIdValidation, 
  handleValidationErrors 
} = require('../middleware/validation');

/**
 * GET /payments
 * Get all payments with their latest status
 */
router.get('/', getAllPayments);

/**
 * GET /payments/{payment_id}/events
 * Get all events for a specific payment ID (sorted by received_at)
 */
router.get('/:payment_id/events',
  paymentIdValidation,
  handleValidationErrors,
  getPaymentEvents
);

/**
 * GET /payments/{payment_id}
 * Get detailed information for a specific payment
 */
router.get('/:payment_id',
  paymentIdValidation,
  handleValidationErrors,
  getPaymentDetails
);

module.exports = router;
