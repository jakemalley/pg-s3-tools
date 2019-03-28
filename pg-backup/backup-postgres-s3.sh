#!/bin/sh

## Backup a Postgres database using pg_dump and ship
## to an S3 object store.

if [ -z "$PGDUMP_PREFIX" ]; then
    DUMP_PREFIX="pg_dump"
else
    DUMP_PREFIX="$PGDUMP_PREFIX"
fi

DUMP_TIMESTAMP=`date +%Y%m%d_%H%M%S`
DUMP_FILE_NAME="${DUMP_PREFIX}_${DUMP_TIMESTAMP}.pgdump"

# Simple log function with the date.
echo_log () {
    echo "`date`: $*"
}

# Validate environment variables
validate() {
    if [ -z $PGDATABASE ]; then
        echo_log "Failed to start backup: env PGDATABASE not set"
    fi

    if [ -z $S3_HOST ]; then
        echo_log "Failed to start backup: S3_HOST not set"
        exit 1
    fi

    if [ -z $S3_HOST_BUCKET ]; then
        echo_log "Failed to start backup: S3_HOST_BUCKET not set"
        exit 1
    fi

    if [ -z $S3_BUCKET ]; then
        echo_log "Failed to start backup: S3_BUCKET not set"
        exit 1
    fi

    if [ -z $AWS_ACCESS_KEY_ID ]; then
        echo_log "Failed to start backup: AWS_ACCESS_KEY_ID not set"
        exit 1
    fi

    if [ -z $AWS_SECRET_ACCESS_KEY ]; then
        echo_log "Failed to start backup: AWS_SECRET_ACCESS_KEY not set"
        exit 1
    fi
}

# Use pg_dump to dump the database.
create_pg_dump() {
    echo_log "Creating backup: ${DUMP_FILE_NAME}"
    if pg_dump --create --no-password --format=c --blobs > $DUMP_FILE_NAME; then
        echo_log "Backup created successfully: ${DUMP_FILE_NAME}"
        return 0
    else
        echo_log "Failed to create backup using pg_dump"
        rm -f $DUMP_FILE_NAME
        exit 1
    fi
}

# Compress the .pgdump file using gzip.
compress_pg_dump() {
    echo_log "Compressing backup: ${DUMP_FILE_NAME}"
    if gzip $DUMP_FILE_NAME; then
        echo_log "Backup compressed successfully: ${DUMP_FILE_NAME}.gz"
        return 0
    else
        echo_log "Failed to compress backup using gzip"
        exit 1
    fi
}

# Upload the .pgdump.gz file to the object store.
upload_pg_dump() {
    echo_log "Uploading to object store: s3://${S3_BUCKET}/${DUMP_FILE_NAME}.gz"
    if s3cmd put ${S3CMD_ARG} ${DUMP_FILE_NAME}.gz s3://${S3_BUCKET}; then
        echo_log "Uploaded to object store successfully: s3://${S3_BUCKET}/${DUMP_FILE_NAME}.gz"
        return 0
    else
        echo_log "Failed to upload to object store: s3://${S3_BUCKET}/${DUMP_FILE_NAME}.gz"
        exit 1
    fi
}

echo_log "Starting backup of database ${PGDATABASE}"

# Validate
validate

# Build s3cmd Args
S3CMD_ARG="--host=${S3_HOST} --host-bucket=${S3_HOST_BUCKET}"

# Run the backup
create_pg_dump
compress_pg_dump
upload_pg_dump

# If we didn't exit 1; then we have successfully uploaded.
echo_log "Backup of database ${PGDATABASE} completed successfully"
exit 0
