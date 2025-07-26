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

USE_GPG=false
if [[ -n "${GPG_PUBLIC_KEY:-}" ]]; then
    USE_GPG=true
    echo "$GPG_PUBLIC_KEY" | base64 -d | gpg --import
fi

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

    if [[ "$USE_GPG" == true ]]; then
        ENCRYPTED_FILENAME="${FILENAME}.gpg"
        gpg --yes --batch --encrypt
        --recipient "$(gpg --with-colons --import-options show-only --import <(echo "$GPG_PUBLIC_KEY" | base64 -d) | awk -F: '/^uid:/ {print $10; exit}')"
        -o "/tmp/$ENCRYPTED_FILENAME" "/tmp/$FILENAME"
        echo "Uploading $ENCRYPTED_FILENAME to MinIO"
        mc cp "/tmp/$ENCRYPTED_FILENAME" myminio/"$MINIO_BUCKET"/"$ENCRYPTED_FILENAME"
        rm "/tmp/$ENCRYPTED_FILENAME"
    else
        echo "Uploading unencrypted dump $FILENAME to MinIO"
        mc cp "/tmp/$FILENAME" myminio/"$MINIO_BUCKET"/"$FILENAME"
    fi
    rm "/tmp/$FILENAME"
done

echo "All dumps uploaded successfully."
