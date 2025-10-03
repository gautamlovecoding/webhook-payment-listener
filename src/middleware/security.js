const { signatureService } = require('../services/signatureService');
const logger = require('../utils/logger');

/**
 * Middleware to validate webhook signature
 */
const validateWebhookSignature = (req, res, next) => {
  try {
    const signature = req.headers['x-webhook-signature'] || 
                     req.headers['x-hub-signature-256'] ||
                     req.headers['authorization'];
    
    if (!signature) {
      logger.warn('Webhook signature missing', {
        ip: req.ip,
        headers: req.headers
      });
      
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Webhook signature is required'
      });
    }

    // Get raw body for signature validation
    const rawBody = req.rawBody;
    
    if (!rawBody) {
      logger.error('Raw body missing for signature validation');
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Unable to verify signature: raw body missing'
      });
    }

    // Validate signature
    const isValid = signatureService.validateSignatureHeader(signature, rawBody);
    
    if (!isValid) {
      logger.warn('Invalid webhook signature', {
        ip: req.ip,
        signature: signature.substring(0, 20) + '...', // Log partial signature for debugging
        bodyLength: rawBody.length
      });
      
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Invalid webhook signature'
      });
    }

    logger.info('Webhook signature validated successfully', {
      ip: req.ip,
      bodyLength: rawBody.length
    });

    next();
  } catch (error) {
    logger.error('Error validating webhook signature:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Error validating signature'
    });
  }
};

/**
 * Middleware to capture raw body for signature verification
 * This must be used before express.json() middleware
 */
const captureRawBody = (req, res, next) => {
  if (req.headers['content-type'] && req.headers['content-type'].includes('application/json')) {
    let data = '';
    
    req.setEncoding('utf8');
    req.on('data', chunk => {
      data += chunk;
    });
    
    req.on('end', () => {
      req.rawBody = Buffer.from(data, 'utf8');
      // Parse JSON manually since we need both raw and parsed body
      try {
        req.body = JSON.parse(data);
        next();
      } catch (error) {
        return res.status(400).json({
          error: 'Invalid JSON',
          message: 'Request body must be valid JSON'
        });
      }
    });
  } else {
    next();
  }
};

/**
 * Rate limiting based on IP (simple in-memory implementation)
 */
class SimpleRateLimiter {
  constructor(maxRequests = 100, windowMs = 15 * 60 * 1000) { // 100 requests per 15 minutes
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
    this.requests = new Map();
  }

  middleware() {
    return (req, res, next) => {
      const ip = req.ip || req.connection.remoteAddress;
      const now = Date.now();
      const windowStart = now - this.windowMs;

      // Clean old entries
      if (!this.requests.has(ip)) {
        this.requests.set(ip, []);
      }

      const ipRequests = this.requests.get(ip);
      const recentRequests = ipRequests.filter(timestamp => timestamp > windowStart);
      
      if (recentRequests.length >= this.maxRequests) {
        logger.warn('Rate limit exceeded', {
          ip,
          requests: recentRequests.length,
          maxRequests: this.maxRequests
        });
        
        return res.status(429).json({
          error: 'Too Many Requests',
          message: 'Rate limit exceeded. Please try again later.',
          retry_after: Math.ceil(this.windowMs / 1000)
        });
      }

      // Add current request
      recentRequests.push(now);
      this.requests.set(ip, recentRequests);

      next();
    };
  }
}

const rateLimiter = new SimpleRateLimiter();

module.exports = {
  validateWebhookSignature,
  captureRawBody,
  rateLimiter
};
