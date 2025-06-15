#!/bin/bash
# ************************************************************************************
# Script Name: patchr.sh
#
# This script safely patches a remote file on a server using one of two modes:
#   1. Upload a local file and replace a target remote file.
#   2. Recover the original remote file from a backup.
#
# Steps (in patch mode):
#   1. Upload a local file (`LOCAL_FILE`) to a temporary location (`REMOTE_UPLOAD_FILE`) on the remote server.
#   2. Backup the target remote file (`REMOTE_FILE`) to a backup path (`REMOTE_BACKUP_FILE`).
#   3. Overwrite the remote target file (`REMOTE_FILE`) with the uploaded file.
#
# Steps (in recover mode):
#   1. Overwrite the current remote file (`REMOTE_FILE`) with the backup (`REMOTE_BACKUP_FILE`).
#
# Features:
#   - Prompts user confirmation before each critical step unless `SILENT=true`.
#   - Supports both `rsync` and `scp` for file transfer (set `USE_RSYNC=true` to use rsync).
#   - Terminates immediately on error to avoid partial operations (`set -e`).
#
# Prerequisites:
#   - Set the required variables in `./AAA/config/server.sh`.
#
# Usage:
#   ./patchr.sh            # Patch remote file
#   ./patchr.sh recover    # Recover from backup
#
# Author: Craig Brown
# Since: 1.1.0
# Date: April 16, 2025
# ************************************************************************************

# ================================================================== Required Configurations
source ./AAA/config/server.sh
# Example (in server.sh):
# REMOTE_HOST='192.168.127.131'
# REMOTE_SSH_PORT='22'
# REMOTE_USER='test99'
# REMOTE_PWD='testpwd'

# Upload the LOCAL_FILE to the REMOTE_UPLOAD_FILE
LOCAL_FILE='./AAA/assets/example-patch.txt'
REMOTE_UPLOAD_FILE='~/tmp/example-patch.txt.upload'

# Copy the REMOTE_FILE to REMOTE_BACKUP_FILE before overwriting
REMOTE_FILE='~/example-patch-remote.txt'
REMOTE_BACKUP_FILE='~/tmp/example-patch-remote.txt.bak'

# ================================================================== Optional Configurations
SILENT=false
USE_RSYNC=false

# ================================================================== Functions
set -e
trust_host() {
  echo "[INFO] Trusting $REMOTE_HOST:$REMOTE_SSH_PORT"
  ssh-keygen -R "$REMOTE_HOST" > /dev/null 2>&1
  ssh-keyscan -p "$REMOTE_SSH_PORT" "$REMOTE_HOST" >> ~/.ssh/known_hosts 2>/dev/null
}
resolve_remote_path() {
  local raw_path="$1"
  local resolved_path
  resolved_path=$(sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "echo $raw_path")
  echo "$resolved_path"
}


ask() {
  if [[ "$SILENT" == true ]]; then
    return 0
  fi
  local prompt="${1:-Are you sure? (y/n): }"
  while true; do
    read -p "$prompt" user_choice
    case "$user_choice" in
      [Yy]) return 0 ;;
      [Nn]) echo "Aborted by user."; exit 1 ;;
      *) echo "Please enter y or n." ;;
    esac
  done
}

remote_execute() {
  sshpass -p "$REMOTE_PWD" ssh "$REMOTE_USER@$REMOTE_HOST" "$1"
}

upload_file() {
  remote_dir=$(sshpass -p "$REMOTE_PWD" ssh "$REMOTE_USER@$REMOTE_HOST" "dirname \"$resolved_remote_upload_file\"")

  if ! sshpass -p "$REMOTE_PWD" ssh "$REMOTE_USER@$REMOTE_HOST" "[ -d \"$remote_dir\" ]"; then
    echo "[INFO] Remote directory '$remote_dir' does not exist. Creating it..."
    sshpass -p "$REMOTE_PWD" ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$remote_dir\""
  fi

  if [[ "$USE_RSYNC" == true ]]; then
    sshpass -p "$REMOTE_PWD" rsync -avz "$LOCAL_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_UPLOAD_FILE"
  else
    sshpass -p "$REMOTE_PWD" scp -P "${REMOTE_SSH_PORT:-22}" "$LOCAL_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_UPLOAD_FILE"
  fi
}
# ================================================================== Logic
trust_host
resolved_remote_upload_file=$(resolve_remote_path "$REMOTE_UPLOAD_FILE")
resolved_remote_file=$(resolve_remote_path "$REMOTE_FILE")
# ================================================================== Recovery Mode
if [ "$1" == "recover" ]; then
  RECOVER_COMMAND="cp $REMOTE_BACKUP_FILE $REMOTE_FILE -f"
  ask "Do you want to restore the remote file '$REMOTE_FILE' from the backup file '$REMOTE_BACKUP_FILE'? (y/n): "
  remote_execute "$RECOVER_COMMAND"
  echo "[INFO] Recovery completed."
  exit 0
fi

# ================================================================== 1. Upload File
echo "==================================== Upload the local file"
echo "Local file info:"
ls -al "$LOCAL_FILE"

if remote_execute "[ -f \"$REMOTE_UPLOAD_FILE\" ]"; then
  ask "The remote file '$REMOTE_UPLOAD_FILE' already exists. Do you want to overwrite it with '$LOCAL_FILE'? (y/n): "
else
  ask "Do you want to upload '$LOCAL_FILE' to '$REMOTE_UPLOAD_FILE'? (y/n): "
fi

upload_file
echo
echo "Upload completed. Printing uploaded file info:"
remote_execute "ls -al $REMOTE_UPLOAD_FILE"
ask "Is the local file successfully uploaded? (y/n): "
echo

# ================================================================== 2. Backup File
echo "==================================== Backup the server file"
if ! remote_execute "[ -f \"$resolved_remote_file\" ]"; then
  echo "[ERROR] Remote file does not exist: $REMOTE_FILE"
  echo "Aborting script."
  exit 1
fi

echo "Remote file info before backup:"
remote_execute "ls -al $REMOTE_FILE"
ask "Do you want to back up the remote file '$REMOTE_FILE' to '$REMOTE_BACKUP_FILE'? (y/n): "
remote_execute "cp $REMOTE_FILE $REMOTE_BACKUP_FILE -f"
echo
echo "Backup completed. Printing backup file info:"
remote_execute "ls -al $REMOTE_BACKUP_FILE"
ask "Is the backup file created successfully? (y/n): "
echo

# ================================================================== 3. Overwrite File
echo "==================================== Overwrite the server file"
remote_execute "ls -al $REMOTE_UPLOAD_FILE"
ask "Do you want to overwrite the remote file '$REMOTE_FILE' with the uploaded file '$REMOTE_UPLOAD_FILE'? (y/n): "
remote_execute "cp $REMOTE_UPLOAD_FILE $REMOTE_FILE -f"
echo
echo "Overwrite completed. Final file info:"
remote_execute "ls -al $REMOTE_FILE"
