#!/bin/bash

# Webhook Payment Listener - Quick Setup Script
# This script helps you get started quickly with the webhook payment listener

set -e

echo "🚀 Webhook Payment Listener - Quick Setup"
echo "========================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 16+ first."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "❌ Node.js version 16+ required. Current version: $(node --version)"
    exit 1
fi

echo "✅ Node.js $(node --version) detected"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "⚠️  PostgreSQL is not detected. Please ensure PostgreSQL 12+ is installed and running."
    echo "   Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "   macOS: brew install postgresql"
    echo "   Or use Docker: docker run --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -d postgres"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ PostgreSQL detected"
fi

# Install dependencies
echo ""
echo "📦 Installing Node.js dependencies..."
npm install

echo ""
echo "🗄️  Database Setup Options"
echo "========================="

echo "Choose your database setup method:"
echo "1. 🐳 Docker PostgreSQL (Recommended - Easy setup)"
echo "2. 🔧 Manual PostgreSQL (Use existing PostgreSQL installation)"
echo ""

read -p "Choose option (1 or 2): " -n 1 -r
echo

if [[ $REPLY =~ ^[1]$ ]]; then
    echo ""
    echo "🐳 Setting up Docker PostgreSQL..."
    
    # Check if Docker is available
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        if docker info &> /dev/null; then
            echo "✅ Docker is ready"
            ./docker-setup.sh
        else
            echo "❌ Docker daemon is not running. Please start Docker and try again."
            echo "   Or choose manual setup option."
            exit 1
        fi
    else
        echo "❌ Docker or Docker Compose not found."
        echo "   Please install Docker and Docker Compose first, or choose manual setup."
        exit 1
    fi
    
elif [[ $REPLY =~ ^[2]$ ]]; then
    echo ""
    echo "🔧 Manual PostgreSQL setup selected..."
    
    # Check if .env exists
    if [ ! -f ".env" ]; then
        echo "📋 Creating .env file from template..."
        cp .env.example .env
        echo "✅ Environment file created: .env"
        echo "   Please edit .env with your PostgreSQL credentials before continuing"
    else
        echo "✅ Environment file already exists: .env"
    fi
    
    echo ""
    echo "⚠️  Manual setup requires:"
    echo "   1. Edit .env with your PostgreSQL credentials"
    echo "   2. Create database: createdb webhook_payments"
    echo "   3. Run migrations: npm run db:migrate"
    
else
    echo "❌ Invalid option selected"
    exit 1
fi

echo ""
echo "🛠️  Available Commands"
echo "==================="
echo ""
echo "Development:"
echo "  npm run dev          - Start development server with auto-reload"
echo "  npm start            - Start production server"
echo ""
echo "Database:"
echo "  npm run db:migrate   - Run database migrations (manual setup)"
echo ""
echo "Docker (if using Docker):"
echo "  npm run docker:start - Start PostgreSQL container"
echo "  npm run docker:stop  - Stop containers"
echo "  npm run docker:db    - Access database shell"
echo "  npm run docker:admin - Start pgAdmin UI"
echo ""
echo "Testing:"
echo "  ./testing/curl_examples.sh    - Run comprehensive test suite"
echo "  node testing/signature_generator.js - Generate webhook signatures"
echo ""
echo "🏃‍♂️ Next Steps:"
echo "=============="
echo ""
if [[ $REPLY =~ ^[1]$ ]]; then
    echo "✅ Docker PostgreSQL is ready!"
    echo ""
    echo "1. Start the server:"
    echo "   npm run dev"
    echo ""
    echo "2. Test the API:"
    echo "   ./testing/curl_examples.sh"
else
    echo "📝 For Manual PostgreSQL setup:"
    echo ""
    echo "1. Edit database configuration:"
    echo "   nano .env"
    echo ""
    echo "2. Create database (PostgreSQL):"
    echo "   createdb webhook_payments"
    echo ""
    echo "3. Run migrations:"
    echo "   npm run db:migrate"
    echo ""
    echo "4. Start the server:"
    echo "   npm run dev"
    echo ""
    echo "5. Test the API:"
    echo "   ./testing/curl_examples.sh"
fi
echo ""
echo "📖 Documentation:"
echo "   README.md  - Getting started guide"
echo "   DOCS.md    - Complete API documentation"
echo ""
echo "🎉 Setup complete! Ready to handle secure webhook events."

# Make scripts executable
chmod +x testing/curl_examples.sh

echo ""
echo "✅ All setup scripts are now executable"
echo ""
echo "🔗 Quick Links:"
echo "   Health Check: http://localhost:3000/health"
echo "   API Docs:     http://localhost:3000/"
echo "   Webhook URL:  http://localhost:3000/webhook/payments"
