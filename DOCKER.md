# 🐳 Docker Setup Guide

This guide explains how to use Docker for the Webhook Payment Listener system.

## Why Docker?

✅ **Easy Setup** - No PostgreSQL installation required  
✅ **Consistent Environment** - Same database version everywhere  
✅ **Quick Testing** - Instant database reset and cleanup  
✅ **Production Ready** - Same containers in dev and production  

## Quick Start

```bash
# Everything in one command
./quick-start-docker.sh
```

## Manual Docker Setup

### 1. Start PostgreSQL

```bash
# Start database
npm run docker:setup

# Or just the database container
npm run docker:start
```

### 2. Verify Database

```bash
# Check database status
npm run docker:logs

# Access database shell
npm run docker:db

# In the database shell, run:
\dt                              # List tables
SELECT COUNT(*) FROM payment_events;  # Check data
```

### 3. Start Application

```bash
npm run dev
```

## Docker Commands Reference

| Command | Description |
|---------|-------------|
| `npm run docker:setup` | Complete Docker setup with database |
| `npm run docker:start` | Start PostgreSQL container |
| `npm run docker:stop` | Stop all containers |
| `npm run docker:logs` | View PostgreSQL logs |
| `npm run docker:db` | Access database shell |
| `npm run docker:admin` | Start pgAdmin web interface |
| `npm run docker:reset` | Reset database (delete all data) |

## Database Connection Details

When using Docker PostgreSQL:

```env
DATABASE_URL=postgresql://webhook_user:webhook_password@localhost:5432/webhook_payments
DB_HOST=localhost
DB_PORT=5432
DB_NAME=webhook_payments
DB_USER=webhook_user
DB_PASSWORD=webhook_password
```

## pgAdmin Web Interface

Access the database through a web interface:

```bash
# Start pgAdmin
npm run docker:admin

# Open browser: http://localhost:8080
# Login: admin@webhook.local / admin123
```

**Add Database Server in pgAdmin:**
- Host: `postgres` (container name)
- Port: `5432`
- Database: `webhook_payments`
- Username: `webhook_user`
- Password: `webhook_password`

## Docker Compose Services

The `docker-compose.yml` includes:

### 🗄️ PostgreSQL Database
- **Image:** `postgres:15-alpine`
- **Port:** `5432`
- **Volume:** Persistent data storage
- **Init:** Automatic schema creation

### 🖥️ pgAdmin (Optional)
- **Image:** `dpage/pgadmin4`
- **Port:** `8080`
- **Profile:** `admin` (start with `npm run docker:admin`)

## Development Workflow

```bash
# Day 1: Initial setup
./quick-start-docker.sh

# Daily development
npm run docker:start    # Start database
npm run dev            # Start application

# Testing
./testing/curl_examples.sh

# Database management
npm run docker:db      # Direct SQL access
npm run docker:admin   # Web interface

# End of day
npm run docker:stop    # Stop containers
```

## Production Docker Setup

For production deployment:

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://webhook_user:webhook_password@postgres:5432/webhook_payments
    depends_on:
      - postgres
      
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: webhook_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # Use secrets
      POSTGRES_DB: webhook_payments
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always
```

## Troubleshooting

### Container Won't Start

```bash
# Check Docker daemon
docker info

# Check container status
docker-compose ps

# View detailed logs
docker-compose logs postgres

# Force restart
npm run docker:reset
```

### Database Connection Issues

```bash
# Test database connectivity
npm run docker:db

# If connection fails, check:
docker-compose exec postgres pg_isready -U webhook_user -d webhook_payments

# Check container networking
docker network ls
docker network inspect civic_data_payment_webhook_network
```

### Permission Issues

```bash
# Fix script permissions
chmod +x *.sh
chmod +x testing/*.sh

# Check Docker permissions (Linux)
sudo usermod -aG docker $USER
# Then logout/login or run: newgrp docker
```

### Data Persistence

```bash
# View Docker volumes
docker volume ls

# Inspect volume
docker volume inspect civic_data_payment_postgres_data

# Backup database
docker-compose exec postgres pg_dump -U webhook_user -d webhook_payments > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T postgres psql -U webhook_user -d webhook_payments
```

### Clean Reset

```bash
# Complete cleanup (removes all data)
npm run docker:stop
docker-compose down -v
docker volume prune
docker system prune

# Fresh start
npm run docker:setup
```

## VS Code Integration

For VS Code users, add these tasks to `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Docker: Start Database",
            "type": "shell",
            "command": "npm run docker:start",
            "group": "build"
        },
        {
            "label": "Docker: Stop Database", 
            "type": "shell",
            "command": "npm run docker:stop",
            "group": "build"
        },
        {
            "label": "Docker: Database Shell",
            "type": "shell", 
            "command": "npm run docker:db",
            "group": "test"
        }
    ]
}
```

## Performance Tips

### Development
- Use volume mounts for fast file changes
- Enable BuildKit for faster builds: `DOCKER_BUILDKIT=1`
- Use `.dockerignore` to exclude unnecessary files

### Production
- Use multi-stage builds for smaller images
- Set appropriate memory limits
- Use restart policies: `restart: unless-stopped`
- Monitor with `docker stats`

## Security Best Practices

### Development
```bash
# Use strong passwords (change from defaults)
POSTGRES_PASSWORD=your_secure_password_here

# Bind to localhost only
ports:
  - "127.0.0.1:5432:5432"
```

### Production
```bash
# Use Docker secrets
echo "secure_password" | docker secret create postgres_password -

# Network isolation
networks:
  backend:
    internal: true
```

## Backup Strategy

```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec postgres pg_dump -U webhook_user -d webhook_payments > backups/backup_$DATE.sql

# Retention (keep last 7 days)
find backups/ -name "backup_*.sql" -mtime +7 -delete
```

This Docker setup provides a robust, scalable foundation for your webhook payment listener system! 🚀
