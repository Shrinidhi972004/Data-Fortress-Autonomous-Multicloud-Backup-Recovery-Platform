# File Upload Application

A simple full-stack web application for file upload and management, designed as a test workload for backup and recovery systems.

## Architecture

- **Frontend**: React application (served via Nginx)
- **Backend**: Node.js with Express.js
- **Database**: MongoDB
- **File Storage**: Local filesystem (`/uploads` directory)

## Features

- File upload with metadata storage
- File listing and viewing
- File deletion
- Health check endpoint for monitoring
- Docker Compose setup

## Quick Start

1. **Setup**:
   ```bash
   cd file-upload
   cp .env.example .env
   ```

2. **Run with Docker Compose**:
   ```bash
   docker-compose up -d
   ```

3. **Access**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000
   - Health Check: http://localhost:5000/health

## API Endpoints

- `GET /health` - Health check
- `GET /api/files` - List all files
- `POST /api/files/upload` - Upload a file
- `GET /api/files/:id` - Get file metadata
- `DELETE /api/files/:id` - Delete a file
- `GET /api/files/:id/download` - Download a file

## Development

### Backend Development
```bash
cd backend
npm install
npm run dev
```

### Frontend Development
```bash
cd frontend
npm install
npm start
```

## File Structure

```
file-upload/
├── backend/          # Node.js API server
├── frontend/         # React application
├── uploads/          # File storage directory
├── docker-compose.yml
├── .env.example
└── README.md
```

## Backup Considerations

- **Database**: MongoDB data stored in `mongodb_data` volume
- **Files**: Uploaded files stored in `./uploads` directory
- **Configuration**: Environment variables in `.env` file

For backup testing:
1. Upload files through the web interface
2. Backup the `./uploads` directory and MongoDB data
3. Test disaster recovery scenarios

## Monitoring

The `/health` endpoint returns:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-15T10:30:00Z",
  "database": "connected",
  "uptime": 3600
}
```

## Environment Variables

See `.env.example` for required environment variables.
