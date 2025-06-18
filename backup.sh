#!/bin/bash
set -euo pipefail

# Environment variables required
: "${MINIO_ENDPOINT:?Need to set MINIO_ENDPOINT}"
: "${MINIO_ACCESS_KEY:?Need to set MINIO_ACCESS_KEY}"
: "${MINIO_SECRET_KEY:?Need to set MINIO_SECRET_KEY}"
: "${MINIO_BUCKET:?Need to set MINIO_BUCKET}"
: "${POSTGRES_USER:?Need to set POSTGRES_USER}"
: "${POSTGRES_PASSWORD:?Need to set POSTGRES_PASSWORD}"
: "${POSTGRES_HOST:?Need to set POSTGRES_HOST}"
: "${POSTGRES_PORT:=5432}"
: "${DATABASES:?Need to set DATABASES (comma-separated)}"

# Set PGPASSWORD so pg_dump can authenticate
export PGPASSWORD="$POSTGRES_PASSWORD"

# Configure MinIO client
mc alias set myminio "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"

# Ensure bucket exists
mc mb --ignore-existing myminio/"$MINIO_BUCKET"

# Timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

IFS=',' read -ra DBS <<< "$DATABASES"
for DB in "${DBS[@]}"; do
    echo "Dumping database: $DB"
    FILENAME="${DB}_${TIMESTAMP}.dump"
    pg_dump -Fc -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$DB" -f "/tmp/$FILENAME"
    echo "Uploading $FILENAME to MinIO"
    mc cp "/tmp/$FILENAME" myminio/"$MINIO_BUCKET"/"$FILENAME"
    rm "/tmp/$FILENAME"
done

echo "All dumps uploaded successfully."
