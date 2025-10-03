const crypto = require('crypto');

class SignatureService {
  constructor(secret = process.env.WEBHOOK_SECRET) {
    if (!secret) {
      throw new Error('Webhook secret is required');
    }
    this.secret = secret;
  }

  /**
   * Generate HMAC-SHA256 signature for payload
   * @param {string|Buffer} payload - Raw payload
   * @returns {string} - Hex encoded signature
   */
  generateSignature(payload) {
    return crypto
      .createHmac('sha256', this.secret)
      .update(payload, 'utf8')
      .digest('hex');
  }

  /**
   * Validate HMAC-SHA256 signature
   * @param {string} signature - Received signature (with or without prefix)
   * @param {string|Buffer} payload - Raw payload
   * @returns {boolean} - True if signature is valid
   */
  validateSignature(signature, payload) {
    if (!signature || !payload) {
      return false;
    }

    try {
      // Remove common prefixes like 'sha256=' if present
      const cleanSignature = signature.replace(/^(sha256=|hmac-sha256=)/i, '');
      
      // Generate expected signature
      const expectedSignature = this.generateSignature(payload);
      
      // Use timing-safe comparison to prevent timing attacks
      return crypto.timingSafeEqual(
        Buffer.from(cleanSignature, 'hex'),
        Buffer.from(expectedSignature, 'hex')
      );
    } catch (error) {
      // Invalid hex string or other crypto errors
      return false;
    }
  }

  /**
   * Create signature with prefix for testing
   * @param {string|Buffer} payload - Payload to sign
   * @param {string} prefix - Prefix to add (default: 'sha256=')
   * @returns {string} - Prefixed signature
   */
  createSignatureHeader(payload, prefix = 'sha256=') {
    return prefix + this.generateSignature(payload);
  }

  /**
   * Validate signature from various header formats
   * @param {string} signatureHeader - Header value
   * @param {string|Buffer} payload - Raw payload
   * @returns {boolean} - True if any signature matches
   */
  validateSignatureHeader(signatureHeader, payload) {
    if (!signatureHeader) {
      return false;
    }

    // Handle multiple signatures separated by comma (GitHub style)
    const signatures = signatureHeader.split(',').map(s => s.trim());
    
    return signatures.some(sig => this.validateSignature(sig, payload));
  }
}

// Create singleton instance
const signatureService = new SignatureService();

module.exports = {
  SignatureService,
  signatureService
};
