#!/bin/bash

# Health check script for monitoring

API_URL=${1:-"http://localhost:5000"}
TIMEOUT=${2:-10}

echo "Checking health of File Upload Application..."
echo "API URL: $API_URL"
echo "Timeout: ${TIMEOUT}s"
echo "----------------------------------------"

# Check backend health
echo "Checking backend health..."
BACKEND_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/health_response.json --max-time $TIMEOUT "$API_URL/health" 2>/dev/null)
BACKEND_STATUS=$?

if [ $BACKEND_STATUS -eq 0 ] && [ "$BACKEND_RESPONSE" = "200" ]; then
    echo "Backend: Healthy"
    echo "Response: $(cat /tmp/health_response.json)"
else
    echo "Backend: Unhealthy (HTTP: $BACKEND_RESPONSE, Exit: $BACKEND_STATUS)"
    exit 1
fi

# Check if we can list files
echo ""
echo "Checking API endpoints..."
FILES_RESPONSE=$(curl -s -w "%{http_code}" -o /tmp/files_response.json --max-time $TIMEOUT "$API_URL/api/files" 2>/dev/null)
FILES_STATUS=$?

if [ $FILES_STATUS -eq 0 ] && [ "$FILES_RESPONSE" = "200" ]; then
    echo "Files API: Working"
    FILE_COUNT=$(cat /tmp/files_response.json | grep -o '"totalFiles":[0-9]*' | cut -d':' -f2)
    echo "Total files in system: ${FILE_COUNT:-'unknown'}"
else
    echo "Files API: Not working (HTTP: $FILES_RESPONSE, Exit: $FILES_STATUS)"
fi

# Check frontend (if URL provided)
if [ "$#" -gt 2 ]; then
    FRONTEND_URL=$3
    echo ""
    echo "Checking frontend..."
    FRONTEND_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null --max-time $TIMEOUT "$FRONTEND_URL" 2>/dev/null)
    FRONTEND_STATUS=$?
    
    if [ $FRONTEND_STATUS -eq 0 ] && [ "$FRONTEND_RESPONSE" = "200" ]; then
        echo "Frontend: Accessible"
    else
        echo "Frontend: Not accessible (HTTP: $FRONTEND_RESPONSE, Exit: $FRONTEND_STATUS)"
    fi
fi

echo ""
echo "Health check completed!"
rm -f /tmp/health_response.json /tmp/files_response.json 2>/dev/null
