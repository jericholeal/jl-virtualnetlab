#!/bin/bash

# Pull /home from linuxclient01 (ssh), back up to /srv/backups

set -euo pipefail

### Variables ###
NOW="$(date +"%Y-%m-%d_%H-%M-%S")"
REMOTE_USER="linuxuser"
REMOTE_HOST="192.168.100.101"
SSH_KEY="/home/fsadmin/.ssh/linuxclient01_backup_linuxuser"
SRC_PATH="/home/linuxuser"
TEMP_DIR="$(mktemp -d /tmp/linuxuser01_home.XXXXXX)" # Create TEMP_DIR
BACKUP_DIR="/srv/backups/linuxuser01_home"
ARCHIVE_NAME="linuxuser01_home_$NOW.tar.gz"
LOG_FILE="/var/log/backups/linuxclient01_rsync_$NOW.log"

mkdir -p "$(dirname "$LOG_FILE")"
exec >> "$LOG_FILE" 2>&1

### Functions ###

timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

log() {
    echo "[$(timestamp)] $*"
}

rsync_ssh_to_temp() {
    rsync -azP -e "ssh -i $SSH_KEY" \
    "${REMOTE_USER}@${REMOTE_HOST}:${SRC_PATH}" \
    "$TEMP_DIR"
}

backup() {
    tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$TEMP_DIR" .
}

cleanup() {
    log "Cleaning up temporary directory..."
    rm -rf "$TEMP_DIR"
}

main() {
    trap cleanup EXIT INT TERM

    log "Starting backup of $SRC_PATH on $REMOTE_HOST..."

    if [[ ! -f "$SSH_KEY" ]]; then
        log "ERROR: SSH key not found at $SSH_KEY." >&2
        exit 1
    fi

    ## Ensure backup directory exists ##
    mkdir -p "$BACKUP_DIR"

    if ! rsync_ssh_to_temp; then
        log "ERROR: rsync failed!" >&2
        exit 1
    fi

    if ! backup; then
        log "ERROR: Compression and backup failed!" >&2
        exit 1
    fi

    log "Backup completed successfully: $BACKUP_DIR/$ARCHIVE_NAME"
}

main "$@"