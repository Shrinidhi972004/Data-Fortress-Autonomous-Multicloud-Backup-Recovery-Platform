#!/bin/bash

# Script to populate the file upload app with test data

API_URL=${1:-"http://localhost:5000"}
TEST_FILES_DIR="./test-files"

echo "Populating File Upload App with test data..."
echo "API URL: $API_URL"
echo "==========================================="

# Create test files directory
mkdir -p "$TEST_FILES_DIR"

# Create sample files
echo "Creating sample files..."

# Text file
cat > "$TEST_FILES_DIR/sample-document.txt" << EOF
Sample Document for Testing
===========================

This is a test document created for backup and recovery testing.
Created on: $(date)

File Upload Application Test Data
- Backend: Node.js + Express + MongoDB
- Frontend: React
- Storage: Local filesystem
- Purpose: Data workload testing

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
EOF

# CSV file
cat > "$TEST_FILES_DIR/sample-data.csv" << EOF
ID,Name,Email,Department,Salary
1,John Doe,john.doe@company.com,Engineering,75000
2,Jane Smith,jane.smith@company.com,Marketing,68000
3,Bob Johnson,bob.johnson@company.com,Sales,72000
4,Alice Brown,alice.brown@company.com,HR,65000
5,Charlie Wilson,charlie.wilson@company.com,Finance,80000
EOF

# JSON file
cat > "$TEST_FILES_DIR/config.json" << EOF
{
  "application": "file-upload-app",
  "version": "1.0.0",
  "environment": "test",
  "database": {
    "type": "mongodb",
    "host": "mongo",
    "port": 27017,
    "name": "fileupload"
  },
  "features": {
    "upload": true,
    "download": true,
    "delete": true,
    "statistics": true
  }
}
EOF

echo "Sample files created"

# Function to upload a file
upload_file() {
    local file_path=$1
    local uploaded_by=$2
    local description=$3
    local tags=$4
    
    echo "Uploading: $(basename "$file_path")"
    
    curl -s -X POST \
        -F "file=@$file_path" \
        -F "uploadedBy=$uploaded_by" \
        -F "description=$description" \
        -F "tags=$tags" \
        "$API_URL/api/files/upload" | grep -q "uploaded successfully"
    
    if [ $? -eq 0 ]; then
        echo "Uploaded: $(basename "$file_path")"
    else
        echo "Failed to upload: $(basename "$file_path")"
    fi
}

# Wait for API to be ready
echo ""
echo "Waiting for API to be ready..."
for i in {1..30}; do
    if curl -s "$API_URL/health" > /dev/null 2>&1; then
        echo "API is ready"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

# Upload test files
echo ""
echo "Uploading test files..."

upload_file "$TEST_FILES_DIR/sample-document.txt" "test-user" "Sample text document for testing" "testing,document,text"
upload_file "$TEST_FILES_DIR/sample-data.csv" "data-analyst" "Employee data in CSV format" "testing,data,csv,employees"
upload_file "$TEST_FILES_DIR/config.json" "admin" "Application configuration file" "testing,config,json,settings"

# Check results
echo ""
echo "Checking upload results..."
TOTAL_FILES=$(curl -s "$API_URL/api/files" | grep -o '"totalFiles":[0-9]*' | cut -d':' -f2)
echo "Total files in system: ${TOTAL_FILES:-'0'}"

echo ""
echo "Test data population completed!"
echo ""
echo "You can now:"
echo "  1. View files at: http://localhost:3000"
echo "  2. Test backup: ./backup-example.sh"
echo "  3. Check health: ./health-check.sh"
echo ""
echo "Cleanup test files: rm -rf $TEST_FILES_DIR"
