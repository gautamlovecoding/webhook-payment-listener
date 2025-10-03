#!/bin/bash

# Docker-based Webhook Payment Listener Setup
# This script sets up PostgreSQL using Docker and initializes the database

set -e

echo "🐳 Docker-based Webhook Payment Listener Setup"
echo "=============================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "   Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker $(docker --version | cut -d' ' -f3 | cut -d',' -f1) detected"
echo "✅ Docker Compose $(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1) detected"

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker first."
    exit 1
fi

echo "✅ Docker daemon is running"
echo ""

# Update .env file with Docker credentials
echo "📋 Updating environment configuration for Docker..."
if [ -f ".env" ]; then
    echo "⚠️  Backing up existing .env to .env.backup"
    cp .env .env.backup
fi

cp .env.example .env
echo "✅ Environment file updated with Docker PostgreSQL credentials"
echo ""

# Stop any existing containers
echo "🛑 Stopping any existing containers..."
docker-compose down 2>/dev/null || true

# Start PostgreSQL container
echo "🚀 Starting PostgreSQL container..."
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
timeout=60
counter=0

while ! docker-compose exec -T postgres pg_isready -U webhook_user -d webhook_payments &>/dev/null; do
    if [ $counter -ge $timeout ]; then
        echo "❌ Timeout waiting for PostgreSQL to start"
        echo "🔍 Container logs:"
        docker-compose logs postgres
        exit 1
    fi
    
    echo "   Waiting... ($((counter + 1))/${timeout}s)"
    sleep 1
    ((counter++))
done

echo "✅ PostgreSQL is ready!"
echo ""

# Verify database setup
echo "🔍 Verifying database setup..."
sleep 2

# Check if tables were created
if docker-compose exec -T postgres psql -U webhook_user -d webhook_payments -c "\dt payment_events" &>/dev/null; then
    echo "✅ Database tables created successfully"
else
    echo "❌ Database tables were not created properly"
    echo "🔍 Running manual schema setup..."
    docker-compose exec -T postgres psql -U webhook_user -d webhook_payments -f /docker-entrypoint-initdb.d/01-init.sql
fi

# Show database info
echo ""
echo "📊 Database Information:"
echo "======================"
docker-compose exec -T postgres psql -U webhook_user -d webhook_payments -c "
SELECT 
    'Database: webhook_payments' as info
UNION ALL
SELECT 
    'User: webhook_user' as info
UNION ALL
SELECT 
    'Tables: ' || COUNT(*) || ' created' as info
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'payment_events';
"

echo ""
echo "📋 Sample Data Check:"
docker-compose exec -T postgres psql -U webhook_user -d webhook_payments -c "
SELECT 
    COUNT(*) as sample_events,
    CASE 
        WHEN COUNT(*) > 0 THEN 'Sample data inserted'
        ELSE 'No sample data'
    END as status
FROM payment_events;
"

echo ""
echo "🎉 Docker PostgreSQL setup completed successfully!"
echo ""
echo "📡 Connection Details:"
echo "====================="
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: webhook_payments"
echo "   Username: webhook_user"
echo "   Password: webhook_password"
echo "   Connection URL: postgresql://webhook_user:webhook_password@localhost:5432/webhook_payments"
echo ""
echo "🔧 Docker Commands:"
echo "=================="
echo "   Start database:  docker-compose up -d postgres"
echo "   Stop database:   docker-compose down"
echo "   View logs:       docker-compose logs postgres"
echo "   Access DB:       docker-compose exec postgres psql -U webhook_user -d webhook_payments"
echo ""
echo "🖥️  Optional pgAdmin (Database UI):"
echo "==================================="
echo "   Start pgAdmin:   docker-compose --profile admin up -d"
echo "   Access UI:       http://localhost:8080"
echo "   Login:           admin@webhook.local / admin123"
echo ""
echo "🏃‍♂️ Next Steps:"
echo "=============="
echo "1. Install Node.js dependencies:"
echo "   npm install"
echo ""
echo "2. Start the webhook server:"
echo "   npm run dev"
echo ""
echo "3. Test the API:"
echo "   ./testing/curl_examples.sh"
echo ""
echo "✨ Ready to handle secure webhook events!"
