const PaymentEvent = require('../models/PaymentEvent');
const logger = require('../utils/logger');
const { asyncHandler, NotFoundError } = require('../utils/errors');

/**
 * Get all events for a specific payment ID
 */
const getPaymentEvents = asyncHandler(async (req, res) => {
  const { payment_id } = req.params;

  logger.info('Fetching payment events', { payment_id });

  // Get all events for this payment
  const events = await PaymentEvent.findByPaymentId(payment_id);

  if (events.length === 0) {
    logger.info('No events found for payment', { payment_id });
    return res.status(404).json({
      error: 'No events found',
      message: `No events found for payment ID: ${payment_id}`,
      payment_id
    });
  }

  // Transform events to the required format
  const responseEvents = events.map(event => event.toSummary());

  logger.info('Payment events retrieved successfully', {
    payment_id,
    event_count: events.length
  });

  res.json(responseEvents);
});

/**
 * Get detailed information for a specific payment
 */
const getPaymentDetails = asyncHandler(async (req, res) => {
  const { payment_id } = req.params;

  logger.info('Fetching payment details', { payment_id });

  const events = await PaymentEvent.findByPaymentId(payment_id);

  if (events.length === 0) {
    throw new NotFoundError(`Payment not found: ${payment_id}`);
  }

  // Get payment stats
  const eventTypes = [...new Set(events.map(e => e.event_type))];
  const firstEvent = events[0];
  const lastEvent = events[events.length - 1];

  const paymentDetails = {
    payment_id,
    total_events: events.length,
    event_types: eventTypes,
    first_event_at: firstEvent.received_at,
    last_event_at: lastEvent.received_at,
    current_status: lastEvent.event_type,
    events: events.map(event => ({
      id: event.id,
      event_id: event.event_id,
      event_type: event.event_type,
      received_at: event.received_at,
      payload: event.payload
    }))
  };

  logger.info('Payment details retrieved successfully', {
    payment_id,
    event_count: events.length,
    event_types: eventTypes
  });

  res.json(paymentDetails);
});

/**
 * Get all payments with their latest status
 */
const getAllPayments = asyncHandler(async (req, res) => {
  const limit = parseInt(req.query.limit) || 50;
  const offset = parseInt(req.query.offset) || 0;

  logger.info('Fetching all payments', { limit, offset });

  // Get recent events and group by payment_id
  const events = await PaymentEvent.findAll(limit * 5, offset); // Get more to account for grouping

  // Group events by payment_id and get latest event for each
  const paymentMap = new Map();
  
  for (const event of events) {
    const existing = paymentMap.get(event.payment_id);
    if (!existing || new Date(event.received_at) > new Date(existing.received_at)) {
      paymentMap.set(event.payment_id, event);
    }
  }

  const payments = Array.from(paymentMap.values())
    .slice(0, limit)
    .map(event => ({
      payment_id: event.payment_id,
      latest_event_type: event.event_type,
      last_updated: event.received_at,
      event_count: events.filter(e => e.payment_id === event.payment_id).length
    }));

  logger.info('All payments retrieved successfully', {
    total_payments: payments.length,
    limit,
    offset
  });

  res.json({
    payments,
    pagination: {
      limit,
      offset,
      total: payments.length
    }
  });
});

module.exports = {
  getPaymentEvents,
  getPaymentDetails,
  getAllPayments
};
