const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

/**
 * Generate HMAC-SHA256 signature for webhook payload
 */
class SignatureGenerator {
  constructor(secret = 'test_secret') {
    this.secret = secret;
  }

  generateSignature(payload) {
    const payloadString = typeof payload === 'string' ? payload : JSON.stringify(payload);
    return crypto.createHmac('sha256', this.secret).update(payloadString, 'utf8').digest('hex');
  }

  generateSignatureHeader(payload, prefix = 'sha256=') {
    return prefix + this.generateSignature(payload);
  }
}

/**
 * Load mock payload and generate signature
 */
function loadMockPayload(fileName) {
  const filePath = path.join(__dirname, '..', 'mock_payloads', fileName);
  const payload = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  return payload;
}

/**
 * Generate signatures for all mock payloads
 */
function generateAllSignatures() {
  const generator = new SignatureGenerator();
  const mockFiles = [
    'payment_authorized.json',
    'payment_captured.json',
    'payment_failed.json',
    'payment_refunded.json',
    'payment_disputed.json'
  ];

  console.log('🔐 WEBHOOK SIGNATURE GENERATOR\n');
  console.log('Secret used:', 'test_secret');
  console.log('Algorithm:', 'HMAC-SHA256\n');

  mockFiles.forEach(fileName => {
    const payload = loadMockPayload(fileName);
    // Read the exact file content to match what CURL would send
    const fs = require('fs');
    const path = require('path');
    const filePath = path.join(__dirname, '..', 'mock_payloads', fileName);
    const payloadString = fs.readFileSync(filePath, 'utf8');
    const signature = generator.generateSignatureHeader(payloadString);
    
    console.log(`📄 ${fileName}:`);
    console.log(`   Signature: ${signature}`);
    console.log(`   Event ID:  ${payload.event_id}`);
    console.log(`   Event Type: ${payload.event_type}`);
    console.log(`   Payment ID: ${payload.payment_id}`);
    console.log('');
  });
}

// Run if called directly
if (require.main === module) {
  generateAllSignatures();
}

module.exports = {
  SignatureGenerator,
  loadMockPayload,
  generateAllSignatures
};
