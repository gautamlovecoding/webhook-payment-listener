const PaymentEvent = require('../models/PaymentEvent');
const logger = require('../utils/logger');
const { asyncHandler, ConflictError, ValidationError } = require('../utils/errors');

/**
 * Handle incoming webhook events
 */
const handleWebhook = asyncHandler(async (req, res) => {
  const { event_id, event_type, payment_id } = req.body;
  const payload = req.body;

  logger.info('Processing webhook event', {
    event_id,
    event_type,
    payment_id,
    ip: req.ip
  });

  try {
    // Check for idempotency - if event already exists, return success
    const existingEvent = await PaymentEvent.findByEventId(event_id);
    if (existingEvent) {
      logger.info('Duplicate event detected, returning existing event', {
        event_id,
        existing_id: existingEvent.id
      });
      
      return res.status(200).json({
        message: 'Event already processed',
        event: existingEvent.toJSON(),
        duplicate: true
      });
    }

    // Create new event
    const newEvent = await PaymentEvent.create({
      event_id,
      payment_id,
      event_type,
      payload
    });

    logger.info('Webhook event processed successfully', {
      event_id,
      event_type,
      payment_id,
      db_id: newEvent.id
    });

    res.status(200).json({
      message: 'Event processed successfully',
      event: {
        id: newEvent.id,
        event_id: newEvent.event_id,
        payment_id: newEvent.payment_id,
        event_type: newEvent.event_type,
        received_at: newEvent.received_at
      }
    });

  } catch (error) {
    if (error.message === 'EVENT_ALREADY_EXISTS') {
      // Handle race condition where event was created between check and insert
      logger.warn('Race condition detected for duplicate event', { event_id });
      const existingEvent = await PaymentEvent.findByEventId(event_id);
      
      return res.status(200).json({
        message: 'Event already processed',
        event: existingEvent.toJSON(),
        duplicate: true
      });
    }
    
    logger.error('Error processing webhook event', {
      event_id,
      error: error.message,
      stack: error.stack
    });
    
    throw error;
  }
});

/**
 * Get webhook processing status (for health checks)
 */
const getWebhookStatus = asyncHandler(async (req, res) => {
  // Get some basic stats
  const recentEvents = await PaymentEvent.findAll(5, 0);
  
  res.json({
    status: 'operational',
    message: 'Webhook endpoint is ready to receive events',
    recent_events: recentEvents.length,
    last_event_at: recentEvents.length > 0 ? recentEvents[0].received_at : null,
    timestamp: new Date().toISOString()
  });
});

module.exports = {
  handleWebhook,
  getWebhookStatus
};
