const { query } = require('../database/config');

class PaymentEvent {
  constructor({ id, event_id, payment_id, event_type, payload, received_at, created_at, updated_at }) {
    this.id = id;
    this.event_id = event_id;
    this.payment_id = payment_id;
    this.event_type = event_type;
    this.payload = payload;
    this.received_at = received_at;
    this.created_at = created_at;
    this.updated_at = updated_at;
  }

  /**
   * Create a new payment event
   * @param {Object} eventData - Event data
   * @returns {Promise<PaymentEvent>}
   */
  static async create({ event_id, payment_id, event_type, payload }) {
    const text = `
      INSERT INTO payment_events (event_id, payment_id, event_type, payload)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `;
    const values = [event_id, payment_id, event_type, JSON.stringify(payload)];
    
    try {
      const result = await query(text, values);
      return new PaymentEvent(result.rows[0]);
    } catch (error) {
      if (error.code === '23505') { // Unique violation
        throw new Error('EVENT_ALREADY_EXISTS');
      }
      throw error;
    }
  }

  /**
   * Find an event by event_id
   * @param {string} event_id - Event ID
   * @returns {Promise<PaymentEvent|null>}
   */
  static async findByEventId(event_id) {
    const text = 'SELECT * FROM payment_events WHERE event_id = $1';
    const result = await query(text, [event_id]);
    
    return result.rows.length > 0 ? new PaymentEvent(result.rows[0]) : null;
  }

  /**
   * Get all events for a payment ID
   * @param {string} payment_id - Payment ID
   * @returns {Promise<PaymentEvent[]>}
   */
  static async findByPaymentId(payment_id) {
    const text = `
      SELECT * FROM payment_events 
      WHERE payment_id = $1 
      ORDER BY received_at ASC
    `;
    const result = await query(text, [payment_id]);
    
    return result.rows.map(row => new PaymentEvent(row));
  }

  /**
   * Get all events with pagination
   * @param {number} limit - Limit
   * @param {number} offset - Offset
   * @returns {Promise<PaymentEvent[]>}
   */
  static async findAll(limit = 50, offset = 0) {
    const text = `
      SELECT * FROM payment_events 
      ORDER BY received_at DESC 
      LIMIT $1 OFFSET $2
    `;
    const result = await query(text, [limit, offset]);
    
    return result.rows.map(row => new PaymentEvent(row));
  }

  /**
   * Check if event exists
   * @param {string} event_id - Event ID
   * @returns {Promise<boolean>}
   */
  static async exists(event_id) {
    const text = 'SELECT 1 FROM payment_events WHERE event_id = $1';
    const result = await query(text, [event_id]);
    return result.rows.length > 0;
  }

  /**
   * Get events count for a payment
   * @param {string} payment_id - Payment ID
   * @returns {Promise<number>}
   */
  static async countByPaymentId(payment_id) {
    const text = 'SELECT COUNT(*) FROM payment_events WHERE payment_id = $1';
    const result = await query(text, [payment_id]);
    return parseInt(result.rows[0].count);
  }

  /**
   * Convert to JSON representation for API response
   * @returns {Object}
   */
  toJSON() {
    return {
      id: this.id,
      event_id: this.event_id,
      payment_id: this.payment_id,
      event_type: this.event_type,
      payload: this.payload,
      received_at: this.received_at,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }

  /**
   * Convert to summary format for payment events list
   * @returns {Object}
   */
  toSummary() {
    return {
      event_type: this.event_type,
      received_at: this.received_at
    };
  }
}

module.exports = PaymentEvent;
