#!/bin/bash

# Quick Start Script for Docker-based Webhook Payment Listener
# This script does everything needed to get the system running

set -e

echo "🚀 Webhook Payment Listener - Docker Quick Start"
echo "==============================================="
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16+ first."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker first."
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install
echo "✅ Dependencies installed"
echo ""

# Setup Docker PostgreSQL
echo "🐳 Setting up Docker PostgreSQL..."
./docker-setup.sh

echo ""
echo "🧪 Running quick database test..."
sleep 2

# Test database connection
if docker-compose exec -T postgres psql -U webhook_user -d webhook_payments -c "SELECT 'Database connection successful!' as test;" &>/dev/null; then
    echo "✅ Database connection test passed"
else
    echo "❌ Database connection test failed"
    exit 1
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "🏃‍♂️ Starting the webhook server..."
echo "================================="

# Start the server in the background for testing
npm run dev &
SERVER_PID=$!

# Wait a moment for server to start
sleep 3

# Test if server is running
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Server is running at http://localhost:3000"
    echo ""
    
    # Show server info
    echo "📊 Server Status:"
    curl -s http://localhost:3000/health | jq . 2>/dev/null || curl -s http://localhost:3000/health
    echo ""
    
    echo "🧪 Running API tests..."
    sleep 1
    
    # Run a quick test
    if [ -f "./testing/curl_examples.sh" ]; then
        echo "📋 Running comprehensive test suite..."
        ./testing/curl_examples.sh
    else
        echo "⚠️  Test suite not found, running basic health check only"
    fi
    
    echo ""
    echo "🎊 Everything is working perfectly!"
    echo ""
    echo "🔗 Important URLs:"
    echo "   API Server:      http://localhost:3000"
    echo "   Health Check:    http://localhost:3000/health"
    echo "   API Docs:        http://localhost:3000/"
    echo "   Webhook URL:     http://localhost:3000/webhook/payments"
    echo ""
    echo "🛢️  Database Access:"
    echo "   Direct Access:   npm run docker:db"
    echo "   pgAdmin UI:      npm run docker:admin (then visit http://localhost:8080)"
    echo ""
    echo "📚 Documentation:"
    echo "   README.md        Complete setup guide"
    echo "   DOCS.md          API documentation"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   npm run dev              Start development server"
    echo "   npm run docker:start     Start database only"
    echo "   npm run docker:stop      Stop database"
    echo "   npm run docker:logs      View database logs"
    echo "   ./testing/curl_examples.sh   Run full test suite"
    
    # Keep server running or stop it
    echo ""
    read -p "Keep the server running? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        kill $SERVER_PID 2>/dev/null || true
        echo "🛑 Server stopped"
    else
        echo "🚀 Server continues running in the background (PID: $SERVER_PID)"
        echo "   To stop: kill $SERVER_PID"
    fi
    
else
    echo "❌ Server failed to start"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

echo ""
echo "✨ Webhook Payment Listener is ready to handle secure payment events!"
