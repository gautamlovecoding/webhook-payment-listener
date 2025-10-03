#!/bin/bash

# Webhook Payment Listener - CURL Test Examples
# Make sure the server is running on localhost:3000

BASE_URL="http://localhost:3000"
WEBHOOK_SECRET="test_secret"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Webhook Payment Listener - Test Suite${NC}"
echo -e "${BLUE}===============================================${NC}\n"

# Function to generate HMAC-SHA256 signature
generate_signature() {
    local payload="$1"
    echo -n "$payload" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -hex | awk '{print $2}'
}

# Function to make webhook request
send_webhook() {
    local payload_file="$1"
    local description="$2"
    
    echo -e "${YELLOW}📤 Testing: $description${NC}"
    
    # Read payload
    if [ ! -f "mock_payloads/$payload_file" ]; then
        echo -e "${RED}❌ Payload file not found: mock_payloads/$payload_file${NC}\n"
        return 1
    fi
    
    local payload=$(cat "mock_payloads/$payload_file")
    local signature="sha256=$(generate_signature "$payload")"
    
    echo "📄 Payload: $payload_file"
    echo "🔐 Signature: $signature"
    echo ""
    
    # Send request
    local response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-Webhook-Signature: $signature" \
        -d "$payload" \
        "$BASE_URL/webhook/payments")
    
    local http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
    local response_body=$(echo "$response" | grep -v "HTTP_STATUS")
    
    echo "📊 Response Status: $http_status"
    echo "📋 Response Body:"
    echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    
    if [ "$http_status" = "200" ]; then
        echo -e "${GREEN}✅ Success!${NC}\n"
    else
        echo -e "${RED}❌ Failed!${NC}\n"
    fi
}

# Function to get payment events
get_payment_events() {
    local payment_id="$1"
    local description="$2"
    
    echo -e "${YELLOW}📥 Testing: $description${NC}"
    echo "🆔 Payment ID: $payment_id"
    echo ""
    
    local response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -X GET \
        "$BASE_URL/payments/$payment_id/events")
    
    local http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
    local response_body=$(echo "$response" | grep -v "HTTP_STATUS")
    
    echo "📊 Response Status: $http_status"
    echo "📋 Response Body:"
    echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
    
    if [ "$http_status" = "200" ] || [ "$http_status" = "404" ]; then
        echo -e "${GREEN}✅ Success!${NC}\n"
    else
        echo -e "${RED}❌ Failed!${NC}\n"
    fi
}

# Check if server is running
echo -e "${BLUE}🔍 Checking if server is running...${NC}"
if curl -s "$BASE_URL/health" > /dev/null; then
    echo -e "${GREEN}✅ Server is running${NC}\n"
else
    echo -e "${RED}❌ Server is not running. Please start the server first:${NC}"
    echo -e "${RED}   npm run dev${NC}\n"
    exit 1
fi

# Test 1: Health Check
echo -e "${YELLOW}📊 Health Check${NC}"
curl -s "$BASE_URL/health" | jq .
echo -e "${GREEN}✅ Health check completed${NC}\n"

# Test 2: API Documentation
echo -e "${YELLOW}📚 API Documentation${NC}"
curl -s "$BASE_URL/" | jq .
echo -e "${GREEN}✅ API docs retrieved${NC}\n"

# Test 3: Valid Webhook Events
echo -e "${BLUE}🔔 Testing Valid Webhook Events${NC}"
echo -e "${BLUE}=================================${NC}\n"

send_webhook "payment_authorized.json" "Payment Authorized Event"
send_webhook "payment_captured.json" "Payment Captured Event" 
send_webhook "payment_failed.json" "Payment Failed Event"
send_webhook "payment_refunded.json" "Payment Refunded Event"
send_webhook "payment_disputed.json" "Payment Disputed Event"

# Test 4: Duplicate Event (Idempotency)
echo -e "${BLUE}🔄 Testing Idempotency (Duplicate Events)${NC}"
echo -e "${BLUE}=======================================${NC}\n"

send_webhook "payment_authorized.json" "Duplicate Payment Authorized Event"

# Test 5: Invalid Signature
echo -e "${BLUE}🔒 Testing Invalid Signature${NC}"
echo -e "${BLUE}============================${NC}\n"

echo -e "${YELLOW}📤 Testing: Invalid Signature${NC}"
payload=$(cat "mock_payloads/payment_authorized.json")
echo "🔐 Signature: invalid_signature"
echo ""

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-Webhook-Signature: invalid_signature" \
    -d "$payload" \
    "$BASE_URL/webhook/payments")

http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
response_body=$(echo "$response" | grep -v "HTTP_STATUS")

echo "📊 Response Status: $http_status"
echo "📋 Response Body:"
echo "$response_body" | jq . 2>/dev/null || echo "$response_body"

if [ "$http_status" = "403" ]; then
    echo -e "${GREEN}✅ Correctly rejected invalid signature!${NC}\n"
else
    echo -e "${RED}❌ Should have rejected invalid signature!${NC}\n"
fi

# Test 6: Missing Signature
echo -e "${YELLOW}📤 Testing: Missing Signature${NC}"
payload=$(cat "mock_payloads/payment_authorized.json")
echo "🔐 Signature: (none)"
echo ""

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$BASE_URL/webhook/payments")

http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
response_body=$(echo "$response" | grep -v "HTTP_STATUS")

echo "📊 Response Status: $http_status"
echo "📋 Response Body:"
echo "$response_body" | jq . 2>/dev/null || echo "$response_body"

if [ "$http_status" = "403" ]; then
    echo -e "${GREEN}✅ Correctly rejected missing signature!${NC}\n"
else
    echo -e "${RED}❌ Should have rejected missing signature!${NC}\n"
fi

# Test 7: Invalid JSON
echo -e "${YELLOW}📤 Testing: Invalid JSON${NC}"
signature="sha256=$(generate_signature "invalid json")"
echo "🔐 Signature: $signature"
echo ""

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-Webhook-Signature: $signature" \
    -d "invalid json" \
    "$BASE_URL/webhook/payments")

http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
response_body=$(echo "$response" | grep -v "HTTP_STATUS")

echo "📊 Response Status: $http_status"
echo "📋 Response Body:"
echo "$response_body" | jq . 2>/dev/null || echo "$response_body"

if [ "$http_status" = "400" ]; then
    echo -e "${GREEN}✅ Correctly rejected invalid JSON!${NC}\n"
else
    echo -e "${RED}❌ Should have rejected invalid JSON!${NC}\n"
fi

# Test 8: Get Payment Events
echo -e "${BLUE}📋 Testing Payment Events Retrieval${NC}"
echo -e "${BLUE}===================================${NC}\n"

get_payment_events "pay_12345" "Get events for payment pay_12345"
get_payment_events "pay_54321" "Get events for payment pay_54321"
get_payment_events "pay_nonexistent" "Get events for non-existent payment"

# Test 9: Get All Payments
echo -e "${BLUE}📊 Testing All Payments Retrieval${NC}"
echo -e "${BLUE}=================================${NC}\n"

echo -e "${YELLOW}📥 Testing: Get all payments${NC}"
echo ""

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
    -X GET \
    "$BASE_URL/payments")

http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
response_body=$(echo "$response" | grep -v "HTTP_STATUS")

echo "📊 Response Status: $http_status"
echo "📋 Response Body:"
echo "$response_body" | jq . 2>/dev/null || echo "$response_body"

if [ "$http_status" = "200" ]; then
    echo -e "${GREEN}✅ Success!${NC}\n"
else
    echo -e "${RED}❌ Failed!${NC}\n"
fi

# Test 10: Get Payment Details
echo -e "${BLUE}📄 Testing Payment Details Retrieval${NC}"
echo -e "${BLUE}====================================${NC}\n"

echo -e "${YELLOW}📥 Testing: Get payment details for pay_12345${NC}"
echo ""

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
    -X GET \
    "$BASE_URL/payments/pay_12345")

http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
response_body=$(echo "$response" | grep -v "HTTP_STATUS")

echo "📊 Response Status: $http_status"
echo "📋 Response Body:"
echo "$response_body" | jq . 2>/dev/null || echo "$response_body"

if [ "$http_status" = "200" ]; then
    echo -e "${GREEN}✅ Success!${NC}\n"
else
    echo -e "${RED}❌ Failed!${NC}\n"
fi

echo -e "${BLUE}🎉 Test Suite Completed!${NC}"
echo -e "${BLUE}========================${NC}\n"

echo -e "${GREEN}Summary:${NC}"
echo -e "• Tested webhook signature validation"
echo -e "• Tested idempotency (duplicate event handling)"  
echo -e "• Tested error cases (invalid signature, JSON, missing fields)"
echo -e "• Tested payment events retrieval"
echo -e "• Tested all payments listing"
echo -e "• Tested payment details retrieval"
echo ""
echo -e "${YELLOW}For more detailed testing, check the test files or use Postman with the provided collection.${NC}"
