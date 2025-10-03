const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();

const logger = require('./utils/logger');
const { errorHandler } = require('./utils/errors');

// Import routes
const webhookRoutes = require('./routes/webhooks');
const paymentRoutes = require('./routes/payments');

// Create Express app
const app = express();

// Trust proxy for accurate IP addresses
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// CORS configuration
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Webhook-Signature', 'X-Hub-Signature-256'],
  credentials: false
}));

// Request logging middleware
app.use((req, res, next) => {
  logger.info('Incoming request', {
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: process.env.npm_package_version || '1.0.0'
  });
});

// API documentation endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Webhook Payment Listener',
    version: '1.0.0',
    description: 'Secure webhook listener system for payment providers',
    endpoints: {
      'POST /webhook/payments': 'Receive payment webhook events',
      'GET /webhook/status': 'Get webhook service status',
      'GET /payments': 'Get all payments with latest status',
      'GET /payments/{payment_id}': 'Get detailed payment information',
      'GET /payments/{payment_id}/events': 'Get all events for a payment',
      'GET /health': 'Health check endpoint',
      'GET /': 'API documentation (this endpoint)'
    },
    documentation: '/docs for detailed API documentation'
  });
});

// Mount routes
app.use('/webhook', webhookRoutes);
app.use('/payments', paymentRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.originalUrl} not found`,
    available_endpoints: [
      'POST /webhook/payments',
      'GET /webhook/status',
      'GET /payments',
      'GET /payments/{payment_id}',
      'GET /payments/{payment_id}/events',
      'GET /health'
    ]
  });
});

// Global error handler (must be last)
app.use(errorHandler);

module.exports = app;
