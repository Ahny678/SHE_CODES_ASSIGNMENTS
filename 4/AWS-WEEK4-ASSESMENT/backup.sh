#!/bin/bash

# -----------------------------------------------------------
# backup.sh
# Creates a MySQL database backup and uploads it to S3
# -----------------------------------------------------------

set -e  # Exit immediately if a command fails

# Load variables from the same .env used by docker-compose
set -a
source ./.env
set +a

# -------------------------------
# Configuration
# -------------------------------

# Docker MySQL container name  
MYSQL_CONTAINER="wordpress-db"

# MySQL credentials from .env
DB_USER="$MYSQL_USER"
DB_PASSWORD="$MYSQL_PASSWORD"
DB_NAME="$MYSQL_DATABASE"

# S3 bucket name  
S3_BUCKET="wordpress-backup-tiffany-2026"

# Local backup directory
BACKUP_DIR="/tmp/mysql-backups"
mkdir -p "$BACKUP_DIR"

# Timestamp for filename
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")

# Backup filename
BACKUP_FILE="$BACKUP_DIR/backup-$TIMESTAMP.sql"

# -------------------------------
# Step 1: Create MySQL dump
# -------------------------------

echo "Creating MySQL backup..."
docker exec "$MYSQL_CONTAINER" sh -c "exec mysqldump -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME}" > "$BACKUP_FILE"

echo "Backup created at $BACKUP_FILE"

# -------------------------------
# Step 2: Upload backup to S3
# -------------------------------

echo "Uploading backup to S3..."
aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$(basename $BACKUP_FILE)"

# -------------------------------
# Step 3: Confirmation
# -------------------------------

echo "Backup successfully uploaded to:"
echo "s3://$S3_BUCKET/$(basename $BACKUP_FILE)"
