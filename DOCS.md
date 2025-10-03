# Webhook Payment Listener API Documentation

## Overview

The Webhook Payment Listener is a secure, production-ready system for handling payment webhook events from providers like Razorpay and PayPal. It provides HMAC-SHA256 signature validation, idempotency protection, and comprehensive event storage.

## Base URL

```
http://localhost:3000
```

## Authentication

All webhook endpoints require HMAC-SHA256 signature validation using a shared secret.

### Signature Validation

**Header:** `X-Webhook-Signature`  
**Format:** `sha256=<hex_encoded_signature>`  
**Algorithm:** HMAC-SHA256  
**Secret:** `test_secret` (configurable via environment)

**Example:**
```bash
# Generate signature
echo -n '{"event_id":"evt_001","event_type":"payment_authorized","payment_id":"pay_123"}' | \
  openssl dgst -sha256 -hmac "test_secret" -hex

# Use in request
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: sha256=<generated_signature>" \
  -d '{"event_id":"evt_001",...}' \
  http://localhost:3000/webhook/payments
```

## API Endpoints

### 1. Health Check

**GET** `/health`

Check server health and status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-07-08T12:00:00Z",
  "uptime": 12345,
  "version": "1.0.0"
}
```

---

### 2. API Documentation

**GET** `/`

Get API documentation and available endpoints.

**Response:**
```json
{
  "name": "Webhook Payment Listener",
  "version": "1.0.0",
  "description": "Secure webhook listener system for payment providers",
  "endpoints": {
    "POST /webhook/payments": "Receive payment webhook events",
    "GET /payments/{payment_id}/events": "Get all events for a payment",
    "GET /health": "Health check endpoint"
  }
}
```

---

### 3. Webhook Status

**GET** `/webhook/status`

Get webhook service status and recent activity.

**Response:**
```json
{
  "status": "operational",
  "message": "Webhook endpoint is ready to receive events",
  "recent_events": 5,
  "last_event_at": "2025-07-08T12:01:23Z",
  "timestamp": "2025-07-08T12:05:00Z"
}
```

---

### 4. Receive Webhook Events

**POST** `/webhook/payments`

Process incoming payment webhook events with signature validation and idempotency.

**Headers:**
- `Content-Type: application/json`
- `X-Webhook-Signature: sha256=<signature>` (required)

**Request Body:**
```json
{
  "event_id": "evt_auth_001",
  "event_type": "payment_authorized",
  "payment_id": "pay_12345",
  "timestamp": "2025-07-08T12:00:00Z",
  "payment": {
    "id": "pay_12345",
    "amount": 10000,
    "currency": "INR",
    "method": "card",
    "status": "authorized"
  }
}
```

**Required Fields:**
- `event_id` (string): Unique event identifier
- `event_type` (string): Event type (payment_authorized, payment_captured, payment_failed, payment_refunded, payment_disputed)
- `payment_id` (string): Payment identifier

**Success Response (200):**
```json
{
  "message": "Event processed successfully",
  "event": {
    "id": 123,
    "event_id": "evt_auth_001",
    "payment_id": "pay_12345",
    "event_type": "payment_authorized",
    "received_at": "2025-07-08T12:00:00Z"
  }
}
```

**Duplicate Event Response (200):**
```json
{
  "message": "Event already processed",
  "event": {
    "id": 123,
    "event_id": "evt_auth_001",
    "payment_id": "pay_12345",
    "event_type": "payment_authorized",
    "received_at": "2025-07-08T12:00:00Z"
  },
  "duplicate": true
}
```

---

### 5. Get Payment Events

**GET** `/payments/{payment_id}/events`

Retrieve all events for a specific payment ID, sorted by received_at timestamp.

**Parameters:**
- `payment_id` (path): Payment identifier

**Success Response (200):**
```json
[
  {
    "event_type": "payment_authorized",
    "received_at": "2025-07-08T12:00:00Z"
  },
  {
    "event_type": "payment_captured",
    "received_at": "2025-07-08T12:01:23Z"
  }
]
```

**No Events Response (404):**
```json
{
  "error": "No events found",
  "message": "No events found for payment ID: pay_nonexistent",
  "payment_id": "pay_nonexistent"
}
```

---

### 6. Get Payment Details

**GET** `/payments/{payment_id}`

Get detailed information for a specific payment including all events and metadata.

**Parameters:**
- `payment_id` (path): Payment identifier

**Success Response (200):**
```json
{
  "payment_id": "pay_12345",
  "total_events": 2,
  "event_types": ["payment_authorized", "payment_captured"],
  "first_event_at": "2025-07-08T12:00:00Z",
  "last_event_at": "2025-07-08T12:01:23Z",
  "current_status": "payment_captured",
  "events": [
    {
      "id": 1,
      "event_id": "evt_auth_001",
      "event_type": "payment_authorized",
      "received_at": "2025-07-08T12:00:00Z",
      "payload": {...}
    }
  ]
}
```

---

### 7. Get All Payments

**GET** `/payments`

Get all payments with their latest status and pagination support.

**Query Parameters:**
- `limit` (optional): Number of results (default: 50, max: 100)
- `offset` (optional): Pagination offset (default: 0)

**Success Response (200):**
```json
{
  "payments": [
    {
      "payment_id": "pay_12345",
      "latest_event_type": "payment_captured",
      "last_updated": "2025-07-08T12:01:23Z",
      "event_count": 2
    }
  ],
  "pagination": {
    "limit": 50,
    "offset": 0,
    "total": 1
  }
}
```

## Error Responses

### 400 Bad Request
Invalid JSON payload or missing required fields.

```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "event_id",
      "message": "event_id is required and must be a non-empty string",
      "value": null
    }
  ]
}
```

### 403 Forbidden
Invalid or missing webhook signature.

```json
{
  "error": "Forbidden",
  "message": "Invalid webhook signature"
}
```

### 404 Not Found
Resource not found (payment or events).

```json
{
  "error": "No events found",
  "message": "No events found for payment ID: pay_nonexistent",
  "payment_id": "pay_nonexistent"
}
```

### 409 Conflict
Duplicate event ID (handled gracefully with idempotency).

```json
{
  "message": "Event already processed",
  "duplicate": true
}
```

### 429 Too Many Requests
Rate limit exceeded.

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded. Please try again later.",
  "retry_after": 900
}
```

### 500 Internal Server Error
Server error with optional stack trace in development.

```json
{
  "error": "Internal Server Error",
  "code": "DATABASE_ERROR",
  "timestamp": "2025-07-08T12:00:00Z"
}
```

## Supported Event Types

The system supports the following webhook event types:

1. **payment_authorized** - Payment has been authorized
2. **payment_captured** - Payment has been captured/settled
3. **payment_failed** - Payment has failed
4. **payment_refunded** - Payment has been refunded
5. **payment_disputed** - Payment has been disputed/charged back

## Rate Limiting

- **Limit:** 100 requests per 15-minute window per IP
- **Headers:** Standard rate limiting headers included in responses
- **Behavior:** Returns 429 status when limit exceeded

## Security Features

### Signature Validation
- HMAC-SHA256 with configurable secret
- Timing-safe comparison to prevent timing attacks
- Support for multiple signature formats

### Input Validation
- JSON schema validation
- SQL injection prevention
- XSS protection with Helmet.js

### Rate Limiting
- Per-IP rate limiting
- Configurable thresholds
- Graceful degradation

## Database Schema

### payment_events Table

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PRIMARY KEY | Auto-incrementing ID |
| event_id | VARCHAR(255) UNIQUE | Unique event identifier |
| payment_id | VARCHAR(255) | Payment identifier |
| event_type | VARCHAR(100) | Type of event |
| payload | JSONB | Complete webhook payload |
| received_at | TIMESTAMP | When event was received |
| created_at | TIMESTAMP | Record creation time |
| updated_at | TIMESTAMP | Record update time |

### Indexes
- `idx_payment_events_event_id` on event_id
- `idx_payment_events_payment_id` on payment_id  
- `idx_payment_events_event_type` on event_type
- `idx_payment_events_received_at` on received_at

## Testing

### Mock Payloads
Pre-built JSON payloads are available in `mock_payloads/`:
- `payment_authorized.json`
- `payment_captured.json`
- `payment_failed.json`
- `payment_refunded.json`
- `payment_disputed.json`

### CURL Examples
Run the test suite:
```bash
./testing/curl_examples.sh
```

### Postman Collection
Import `testing/postman_collection.json` for comprehensive API testing with automatic signature generation.

## Monitoring & Observability

### Logging
- Structured JSON logging with Winston
- Request/response logging
- Error tracking with stack traces
- Configurable log levels

### Health Checks
- `/health` endpoint for load balancer checks
- Database connectivity validation
- Service status reporting

### Metrics
- Request counts and response times
- Error rates and types  
- Database query performance
- Rate limiting statistics

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `DATABASE_URL` | PostgreSQL connection string | - |
| `WEBHOOK_SECRET` | HMAC signature secret | test_secret |
| `LOG_LEVEL` | Logging level | info |

### Database Configuration
- PostgreSQL 12+ recommended
- Connection pooling configured
- SSL support for production
- Migration scripts included

## Performance Considerations

### Database
- Proper indexing for fast lookups
- Connection pooling (max 20 connections)
- Query optimization for payment event retrieval

### Caching
- In-memory rate limiting cache
- Potential for Redis integration
- Database query result caching

### Scaling
- Stateless design for horizontal scaling
- Database can be replicated for read queries
- Load balancer friendly with health checks

## Production Deployment

### Requirements
- Node.js 16+
- PostgreSQL 12+
- 512MB+ RAM
- SSL certificate for HTTPS

### Recommended Architecture
```
Internet → Load Balancer → App Servers → Database
                      ↓
                   Monitoring
```

### Security Checklist
- [ ] Use HTTPS in production
- [ ] Rotate webhook secrets regularly  
- [ ] Enable database SSL
- [ ] Configure firewall rules
- [ ] Set up monitoring and alerting
- [ ] Regular security updates

## Support

For issues and questions:
1. Check the logs in `logs/` directory
2. Verify database connectivity
3. Test webhook signatures with provided tools
4. Review error responses and status codes

## API Examples in Different Languages

### JavaScript/Node.js
```javascript
const crypto = require('crypto');
const axios = require('axios');

const secret = 'test_secret';
const payload = JSON.stringify({
  event_id: 'evt_001',
  event_type: 'payment_authorized',
  payment_id: 'pay_123'
});

const signature = crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('hex');

const response = await axios.post('http://localhost:3000/webhook/payments', 
  JSON.parse(payload), {
  headers: {
    'Content-Type': 'application/json',
    'X-Webhook-Signature': `sha256=${signature}`
  }
});
```

### Python
```python
import hmac
import hashlib
import requests
import json

secret = 'test_secret'
payload = json.dumps({
    'event_id': 'evt_001',
    'event_type': 'payment_authorized', 
    'payment_id': 'pay_123'
})

signature = hmac.new(
    secret.encode('utf-8'),
    payload.encode('utf-8'),
    hashlib.sha256
).hexdigest()

response = requests.post(
    'http://localhost:3000/webhook/payments',
    data=payload,
    headers={
        'Content-Type': 'application/json',
        'X-Webhook-Signature': f'sha256={signature}'
    }
)
```

### PHP
```php
<?php
$secret = 'test_secret';
$payload = json_encode([
    'event_id' => 'evt_001',
    'event_type' => 'payment_authorized',
    'payment_id' => 'pay_123'
]);

$signature = hash_hmac('sha256', $payload, $secret);

$ch = curl_init('http://localhost:3000/webhook/payments');
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'X-Webhook-Signature: sha256=' . $signature
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
curl_close($ch);
?>
