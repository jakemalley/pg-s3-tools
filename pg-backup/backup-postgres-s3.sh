#!/bin/sh

## Backup a Postgres database using pg_dump and ship
## to an S3 object store.

# 
# The following environment variables are used:
# PGDUMP_PREFIX - Sets the Prefix of the dumped file.
# PGDATABASE    - Used by pg_dump
# PGHOST        - Used by pg_dump
# PGPORT        - Used by pg_dump
# PGUSER        - Used by pg_dump
# PGPASSWORD    - Used by pg_dump
#
# S3CONFIG      - Used by s3cmd
#               - Defaults to ~/.s3cfg
# S3BUCKET      - Used by s3cmd

if [ -z "$PGDUMP_PREFIX" ]; then
    DUMP_PREFIX="pg_dump"
else
    DUMP_PREFIX="$PGDUMP_PREFIX"
fi

if [ -z "$S3CONFIG" ]; then
    S3_CONFIG_ARG=""
else
    S3_CONFIG_ARG="-c ${S3CONFIG}"
fi

DUMP_TIMESTAMP=`date +%Y%m%d_%H%M%S`
DUMP_FILE_NAME="${DUMP_PREFIX}_${DUMP_TIMESTAMP}.pgdump"

echo_log () {
    echo "`date`: $*"
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
    echo_log "Uploading to object store: s3://${S3BUCKET}/${DUMP_FILE_NAME}.gz"
    if s3cmd put ${S3_CONFIG_ARG} ${DUMP_FILE_NAME}.gz s3://${S3BUCKET}; then
        echo_log "Uploaded to object store successfully: s3://${S3BUCKET}/${DUMP_FILE_NAME}.gz"
        return 0
    else
        echo_log "Failed to upload to object store: s3://${S3BUCKET}/${DUMP_FILE_NAME}.gz"
        exit 1
    fi
}

if [ ! -z $PGDATABASE ] && [ ! -z $S3BUCKET ]; then

    echo_log "Starting backup of database ${PGDATABASE}"
    
    # Run the backup
    create_pg_dump
    compress_pg_dump
    upload_pg_dump

    # If we didn't exit 1; then we have successfully uploaded.
    echo_log "Backup of database ${PGDATABASE} completed successfully"
    exit 0

else
    if [ -z $PGDATABASE ]; then
        echo_log "Failed to start backup: env PGDATABASE not set"
    fi
    if [ -z $S3BUCKET ]; then
        echo_log "Failed to start backup: env S3BUCKET not set"
    fi
    exit 1
fi