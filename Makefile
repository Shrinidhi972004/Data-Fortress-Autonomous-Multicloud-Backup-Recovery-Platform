# File Upload Application - Makefile

.PHONY: help build start stop restart logs clean test backup populate health dev

# Default target
help:
	@echo "File Upload Application - Available Commands:"
	@echo "============================================="
	@echo "  make build      - Build Docker images"
	@echo "  make start      - Start the application (production)"
	@echo "  make dev        - Start in development mode"
	@echo "  make stop       - Stop the application"
	@echo "  make restart    - Restart the application"
	@echo "  make logs       - Show application logs"
	@echo "  make health     - Check application health"
	@echo "  make populate   - Populate with test data"
	@echo "  make backup     - Create a backup"
	@echo "  make clean      - Clean up containers and volumes"
	@echo "  make test       - Run tests (placeholder)"
	@echo ""
	@echo "URLs:"
	@echo "  Frontend: http://localhost:3000"
	@echo "  Backend:  http://localhost:5000"
	@echo "  Health:   http://localhost:5000/health"

# Production build and start
build:
	@echo "Building Docker images..."
	docker-compose build

start: build
	@echo "Starting File Upload Application (Production)..."
	cp .env.example .env
	docker-compose up -d
	@echo "Application started!"
	@echo "Frontend: http://localhost:3000"
	@echo "Backend: http://localhost:5000"

# Development mode
dev:
	@echo "Starting File Upload Application (Development)..."
	cp .env.example .env
	docker-compose -f docker-compose.dev.yml up -d mongo
	@echo "MongoDB started. Run 'cd backend && npm install && npm run dev' for backend"
	@echo "Run 'cd frontend && npm install && npm start' for frontend"

# Stop application
stop:
	@echo "Stopping application..."
	docker-compose down
	docker-compose -f docker-compose.dev.yml down

# Restart application
restart: stop start

# Show logs
logs:
	@echo "Showing application logs..."
	docker-compose logs -f

# Health check
health:
	@echo "Checking application health..."
	./health-check.sh

# Populate with test data
populate:
	@echo "Populating with test data..."
	./populate-test-data.sh

# Create backup
backup:
	@echo "Creating backup..."
	./backup-example.sh

# Clean up
clean:
	@echo "Cleaning up containers and volumes..."
	docker-compose down -v
	docker-compose -f docker-compose.dev.yml down -v
	docker system prune -f
	@echo "Cleanup completed"

# Test placeholder
test:
	@echo "Running tests..."
	@echo "Tests not implemented yet. This is a placeholder."
	
# Quick setup for new users
setup:
	@echo "Setting up File Upload Application..."
	@echo "1. Copying environment file..."
	cp .env.example .env
	@echo "2. Building images..."
	docker-compose build
	@echo "3. Starting application..."
	docker-compose up -d
	@echo "4. Waiting for services to be ready..."
	sleep 10
	@echo "5. Populating test data..."
	./populate-test-data.sh
	@echo ""
	@echo "Setup completed!"
	@echo "Frontend: http://localhost:3000"
	@echo "Backend: http://localhost:5000"
	@echo "Health: http://localhost:5000/health"
