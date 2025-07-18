#!/bin/bash

# Script to backup /srv/smbshare

set -euo pipefail

### Variables ###
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
SRC_DIR="/srv/smbshare/"
TEMP_DIR="$(mktemp -d /tmp/smbshare.XXXXXX)"
BACKUP_DIR="/srv/backups/smbshare"
ARCHIVE_NAME="smbshare_$NOW.tar.gz"
LOG_FILE="/var/log/backups/smbshare_$NOW.log"

### Logging ###
mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

### Functions ###

timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

log() {
    echo "[$(timestamp)] $*"
}

rsync_to_temp() {
    rsync -azP "$SRC_DIR" "$TEMP_DIR"
}

backup() {
    tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$TEMP_DIR" .
}

cleanup() {
    log "Cleaning up temporary directory..."
    rm -rf "$TEMP_DIR"
}

### Main ###

main() {
    trap cleanup EXIT INT TERM

    log "Starting backup of $SRC_DIR..."
    
    ## Check if source directory exists ##
    if [[ ! -d "$SRC_DIR" ]]; then
        log "ERROR: Source directory $SRC_DIR does not exist."
        exit 1
    fi
    
    ## Ensure backup directory exists ##
    mkdir -p "$BACKUP_DIR"   

    if ! rsync_to_temp; then
        log "ERROR: rsync from $SRC_DIR to $TEMP_DIR failed!" >&2
        exit 1
    fi

    if ! backup; then
        log "ERROR: Compression and backup of $TEMP_DIR to $BACKUP_DIR failed!" >&2
        exit 1
    fi   

    log "Backup complete: $BACKUP_DIR/$ARCHIVE_NAME."
}

main "$@"