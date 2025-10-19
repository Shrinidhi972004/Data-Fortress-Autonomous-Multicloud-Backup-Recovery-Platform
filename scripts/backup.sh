#!/bin/bash

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="./backups/backup_$TIMESTAMP"
MONGO_CONTAINER="file-upload-mongo"

echo "Starting backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup uploads
UPLOAD_DIR="../uploads"
if [ -d "$UPLOAD_DIR" ]; then
  cp -r "$UPLOAD_DIR" "$BACKUP_DIR/"
  echo "Files backed up."
else
  echo "WARNING: No uploads directory found!"
fi

# Backup MongoDB
echo "Backing up MongoDB from container: $MONGO_CONTAINER"
docker exec "$MONGO_CONTAINER" mongodump --out /dump
docker cp "$MONGO_CONTAINER":/dump "$BACKUP_DIR/mongo_dump"
docker exec "$MONGO_CONTAINER" rm -rf /dump

echo "Backup completed: $BACKUP_DIR"
