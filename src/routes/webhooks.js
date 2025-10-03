const express = require('express');
const router = express.Router();

const { handleWebhook, getWebhookStatus } = require('../controllers/webhookController');
const { validateWebhookSignature, captureRawBody, rateLimiter } = require('../middleware/security');
const { 
  webhookValidation, 
  handleValidationErrors, 
  validateJsonPayload,
  validateWebhookFields 
} = require('../middleware/validation');

/**
 * POST /webhook/payments
 * Handle incoming payment webhook events
 */
router.post('/payments',
  // Rate limiting
  rateLimiter.middleware(),
  
  // Capture raw body for signature verification AND parse JSON
  captureRawBody,
  
  // Validate JSON payload structure
  validateJsonPayload,
  
  // Validate webhook signature
  validateWebhookSignature,
  
  // Validate required fields exist
  validateWebhookFields,
  
  // Validate field formats and values
  webhookValidation,
  handleValidationErrors,
  
  // Handle the webhook
  handleWebhook
);

/**
 * GET /webhook/status
 * Get webhook service status (for monitoring)
 */
router.get('/status', getWebhookStatus);

module.exports = router;
