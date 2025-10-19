#!/bin/bash

# Usage check
BACKUP_PATH=$1
if [ -z "$BACKUP_PATH" ]; then
  echo "Usage: ./restore.sh <backup_folder_path>"
  exit 1
fi

MONGO_CONTAINER="file-upload-mongo"
UPLOAD_DIR="../uploads"

echo "Starting restore from: $BACKUP_PATH"

# Restore uploads
if [ -d "$BACKUP_PATH/uploads" ]; then
  mkdir -p "$UPLOAD_DIR"
  cp -r "$BACKUP_PATH/uploads/." "$UPLOAD_DIR/"
  echo "Uploads restored to $UPLOAD_DIR"
else
  echo "WARNING: No uploads directory found in backup!"
fi

# Restore MongoDB
if [ -d "$BACKUP_PATH/mongo_dump" ]; then
  echo "Restoring MongoDB inside container: $MONGO_CONTAINER"
  docker cp "$BACKUP_PATH/mongo_dump" "$MONGO_CONTAINER":/restore
  docker exec "$MONGO_CONTAINER" mongorestore --drop /restore
  docker exec "$MONGO_CONTAINER" rm -rf /restore
  echo "MongoDB restored successfully."
else
  echo "WARNING: No mongo_dump directory found in backup!"
fi

echo "Restore completed!"
