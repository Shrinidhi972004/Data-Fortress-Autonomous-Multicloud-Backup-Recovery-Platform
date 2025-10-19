#!/bin/bash

# Data Fortress - AWS Backup Script
# Uploads the latest local backup to S3

# CONFIGURATION
BUCKET_NAME="datafortress-backups-shrinidhi"
REGION="ap-south-1"
STORAGE_CLASS="STANDARD_IA"

# FIND LATEST BACKUP
LATEST_BACKUP=$(ls -td ./backups/*/ 2>/dev/null | head -1)
if [ -z "$LATEST_BACKUP" ]; then
  echo "ERROR: No backups found in ./backups/. Please run backup.sh first."
  exit 1
fi

BACKUP_NAME=$(basename "$LATEST_BACKUP")

echo "Uploading latest backup: $BACKUP_NAME to s3://$BUCKET_NAME ($REGION)"
echo "==========================================="

# UPLOAD TO S3
aws s3 sync "$LATEST_BACKUP" "s3://$BUCKET_NAME/$BACKUP_NAME" \
  --storage-class "$STORAGE_CLASS" \
  --region "$REGION" \
  --delete

if [ $? -eq 0 ]; then
  echo "AWS S3 upload completed successfully."
  echo "Backup folder: $LATEST_BACKUP"
  echo "Cloud path: s3://$BUCKET_NAME/$BACKUP_NAME"
else
  echo "ERROR: Upload failed! Please check AWS credentials, network, or bucket permissions."
  exit 1
fi

# VERIFY UPLOAD
echo "Verifying files in S3..."
aws s3 ls "s3://$BUCKET_NAME/$BACKUP_NAME/" --region "$REGION"

echo "AWS backup process completed."
