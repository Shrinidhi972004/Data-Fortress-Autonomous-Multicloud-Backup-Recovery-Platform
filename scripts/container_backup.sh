#!/bin/bash

# Container-friendly backup script
# This runs inside the backup container

set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/backup/mongodb/backup_$TIMESTAMP"

echo "Starting backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Extract database name from MONGODB_URI
DB_NAME=$(echo "$MONGODB_URI" | sed 's/.*\/\([^?]*\).*/\1/')
MONGO_HOST=$(echo "$MONGODB_URI" | sed 's/mongodb:\/\/\([^\/]*\).*/\1/')

echo "Database: $DB_NAME"
echo "MongoDB Host: $MONGO_HOST"

# Backup uploads (if they exist)
if [ -d "/backup/uploads" ] && [ "$(ls -A /backup/uploads 2>/dev/null)" ]; then
  cp -r /backup/uploads "$BACKUP_DIR/"
  echo "Files backed up from /backup/uploads"
else
  echo "WARNING: No files found in uploads directory"
  mkdir -p "$BACKUP_DIR/uploads"
  echo "Created empty uploads directory in backup"
fi

# Backup MongoDB using mongodump
echo "Backing up MongoDB..."
mongodump --host="$MONGO_HOST" --db="$DB_NAME" --out="$BACKUP_DIR/mongo_dump"

if [ $? -eq 0 ]; then
  echo "MongoDB backup completed successfully"
else
  echo "ERROR: MongoDB backup failed"
  exit 1
fi

echo "Backup completed: $BACKUP_DIR"
echo "Contents:"
ls -la "$BACKUP_DIR"

# Upload to AWS S3 if credentials are available
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "Starting AWS S3 upload..."
  BACKUP_NAME=$(basename "$BACKUP_DIR")
  
  aws s3 sync "$BACKUP_DIR" "s3://${AWS_BUCKET:-datafortress-backups-shrinidhi}/$BACKUP_NAME" \
    --storage-class "STANDARD_IA" \
    --region "${AWS_REGION:-ap-south-1}"
  
  if [ $? -eq 0 ]; then
    echo "AWS S3 upload completed successfully."
    echo "Cloud path: s3://${AWS_BUCKET:-datafortress-backups-shrinidhi}/$BACKUP_NAME"
  else
    echo "ERROR: AWS S3 upload failed!"
    exit 1
  fi
else
  echo "AWS credentials not provided, skipping S3 upload"
fi

echo "Backup process completed successfully!"
