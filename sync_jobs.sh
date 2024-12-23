#!/bin/bash

# Directories (ensure these variables are correctly set before running the script)
AVATARS_DIR="./home/.local/share/signal-cli/avatars"
ATTACHMENTS_DIR="/home/.local/share/signal-cli/attachments"

# Function to sync files (copy only if they don't exist)
sync_files_interval_10s() {
  for file in "$AVATARS_DIR"/*; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      if [ ! -f "$ATTACHMENTS_DIR/$filename.jpg" ]; then
        cp "$file" "$ATTACHMENTS_DIR/$filename.jpg"
        echo "Copied $filename to $ATTACHMENTS_DIR/$filename.jpg"
      fi
    fi
  done
}

# Function to sync files (overwrite existing files)
sync_files_interval_1h() {
  for file in "$AVATARS_DIR"/*; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      cp "$file" "$ATTACHMENTS_DIR/$filename.jpg"
      echo "Overwritten $filename to $ATTACHMENTS_DIR/$filename.jpg"
    fi
  done
}

# Start 10-second interval job
(
  while true; do
    sync_files_interval_10s
    sleep 10
  done
) &

# Start 1-hour interval job
(
  while true; do
    sync_files_interval_1h
    sleep 3600
  done
) &

# Exit script with status 0
exit 0
