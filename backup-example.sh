#!/bin/bash

# Backup script for the File Upload Application

BACKUP_DIR=${1:-"./backups"}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="file-upload-backup-$TIMESTAMP"

echo "Creating backup: $BACKUP_NAME"
echo "Backup directory: $BACKUP_DIR"
echo "=========================================="

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup uploaded files
echo "Backing up uploaded files..."
if [ -d "./uploads" ]; then
    cp -r ./uploads "$BACKUP_DIR/$BACKUP_NAME/"
    echo "Files backup completed"
else
    echo "No uploads directory found"
fi

# Backup MongoDB data
echo ""
echo "Backing up MongoDB data..."
if command -v docker &> /dev/null; then
    # If using Docker
    docker exec file-upload-mongo mongodump --db fileupload --out /tmp/mongodump
    docker cp file-upload-mongo:/tmp/mongodump "$BACKUP_DIR/$BACKUP_NAME/"
    docker exec file-upload-mongo rm -rf /tmp/mongodump
    echo "MongoDB backup completed (Docker)"
elif command -v mongodump &> /dev/null; then
    # If MongoDB tools are installed locally
    mongodump --db fileupload --out "$BACKUP_DIR/$BACKUP_NAME/mongodump"
    echo "MongoDB backup completed (Local)"
else
    echo "MongoDB backup tools not found"
fi

# Backup configuration
echo ""
echo "Backing up configuration..."
cp .env.example "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || echo "No .env.example found"
cp docker-compose.yml "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || echo "No docker-compose.yml found"
echo "Configuration backup completed"

# Create backup metadata
echo ""
echo "Creating backup metadata..."
cat > "$BACKUP_DIR/$BACKUP_NAME/backup-info.txt" << EOF
File Upload Application Backup
==============================
Timestamp: $(date)
Backup Name: $BACKUP_NAME
System: $(uname -a)

Contents:
- uploads/ (uploaded files)
- mongodump/ (MongoDB database)
- .env.example (configuration template)
- docker-compose.yml (Docker setup)

Restore Instructions:
1. Stop the application: docker-compose down
2. Restore files: cp -r uploads/* ./uploads/
3. Restore database: docker exec -i file-upload-mongo mongorestore /tmp/mongodump
4. Start application: docker-compose up -d

Health Check:
Run ./health-check.sh to verify the restore
EOF

# Create compressed archive
echo ""
echo "Creating compressed archive..."
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"
cd - > /dev/null

echo ""
echo "Backup completed successfully!"
echo "Archive: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
echo "Size: $(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)"
echo ""
echo "To restore:"
echo "  1. Extract: tar -xzf $BACKUP_NAME.tar.gz"
echo "  2. Follow instructions in backup-info.txt"
