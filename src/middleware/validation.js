const { body, param, validationResult } = require('express-validator');

/**
 * Webhook payload validation rules
 */
const webhookValidation = [
  body('event_id')
    .isString()
    .notEmpty()
    .withMessage('event_id is required and must be a non-empty string')
    .isLength({ min: 1, max: 255 })
    .withMessage('event_id must be between 1 and 255 characters'),
    
  body('event_type')
    .isString()
    .notEmpty()
    .withMessage('event_type is required and must be a non-empty string')
    .isIn(['payment_authorized', 'payment_captured', 'payment_failed', 'payment_refunded', 'payment_disputed'])
    .withMessage('event_type must be one of: payment_authorized, payment_captured, payment_failed, payment_refunded, payment_disputed'),
    
  body('payment_id')
    .isString()
    .notEmpty()
    .withMessage('payment_id is required and must be a non-empty string')
    .isLength({ min: 1, max: 255 })
    .withMessage('payment_id must be between 1 and 255 characters'),
];

/**
 * Payment ID parameter validation
 */
const paymentIdValidation = [
  param('payment_id')
    .isString()
    .notEmpty()
    .withMessage('payment_id is required and must be a non-empty string')
    .isLength({ min: 1, max: 255 })
    .withMessage('payment_id must be between 1 and 255 characters'),
];

/**
 * Middleware to handle validation errors
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array().map(err => ({
        field: err.path,
        message: err.msg,
        value: err.value
      }))
    });
  }
  
  next();
};

/**
 * Middleware to validate JSON payload exists
 */
const validateJsonPayload = (req, res, next) => {
  if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body)) {
    return res.status(400).json({
      error: 'Invalid JSON payload',
      message: 'Request body must be a valid JSON object'
    });
  }
  next();
};

/**
 * Middleware to validate required webhook fields exist
 */
const validateWebhookFields = (req, res, next) => {
  const requiredFields = ['event_id', 'event_type', 'payment_id'];
  const missingFields = requiredFields.filter(field => !req.body[field]);
  
  if (missingFields.length > 0) {
    return res.status(400).json({
      error: 'Missing required fields',
      message: `The following fields are required: ${missingFields.join(', ')}`,
      missing_fields: missingFields
    });
  }
  
  next();
};

module.exports = {
  webhookValidation,
  paymentIdValidation,
  handleValidationErrors,
  validateJsonPayload,
  validateWebhookFields
};
