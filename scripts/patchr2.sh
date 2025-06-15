#!/bin/bash
# ************************************************************************************
# This script patches a local file to a remote server. The process is designed to be
# as safe and careful as possible.
# Each step will print the executed command and need user to verify the result.
#
# Use sshpass for authentication instead of SSH credentials, as large-scale systems
# often involve many server addresses. Directly using a password is the simplest
# method.
#
# Some servers may not support `rsync -avz`, consider using scp instead.
#
# Rules:
#  * Any error will terminate the script.
#  * After each step, the user must confirm that the process works as intended.
#
# Prerequisites:
#  * Modify the required configurations in the bash file with your own values.
#
# Usage:
#   ./patchr.sh
#        1. Upload the 'LOCAL_FILE' to the 'REMOTE_UPLOAD_FILE'
#        2. Copy the 'REMOTE_FILE' under the folder 'REMOTE_BACKUP_FOLDER'
#           on remote server
#        3. Overwrite the 'REMOTE_FILE' with 'REMOTE_UPLOAD_FILE'
#   ./patchr.sh recover
#        Overwrite the 'REMOTE_FILE' with 'REMOTE_BACKUP_FILE'
#
# Author: Craig Brown
# Since: 1.1.0
# Date: April 16, 2025
# ************************************************************************************

# ================================================================== Required Configurations
# Import global environment variables
source ./AAA/config/server.sh
# Example:
# REMOTE_HOST='192.168.127.131'
# REMOTE_SSH_PORT='22'
# REMOTE_USER='test99'
# REMOTE_PWD='testpwd'

# Upload the LOCAL_FILE to the REMOTE_UPLOAD_FILE
LOCAL_FILE='./AAA/assets/example-patch.txt'
REMOTE_UPLOAD_FILE='~/tmp/example-patch.txt.upload'

# Copy the REMOTE_FILE to the file REMOTE_BACKUP_FILE on the remote server
REMOTE_FILE='~/example-patch-remote.txt'
REMOTE_BACKUP_FILE='~/tmp/example-patch-remote.txt.bak' # For recovery

# ================================================================== Default Configurations
# Ask warning messages
SILENT=false
# Use 'rsync' instead of 'scp'
USE_RSYNC=false
# ================================================================== Functions

set -e

# Choice function to interact with the user
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
  sshpass -p "$REMOTE_PWD" ssh "$LOGIN_USER@$REMOTE_HOST" "$1"
}

if [ "$1" == "recover" ]; then
  # Define the recovery command
  RECOVER_COMMAND="cp $REMOTE_BACKUP_FILE $REMOTE_FILE -f"
  ask "Do you want to restore the remote file '$REMOTE_FILE' from the backup file '$REMOTE_BACKUP_FILE'? (y/n): "
  remote_execute "$RECOVER_COMMAND"
  echo "Recovery command executed."
  exit 0  # Exit after recovery is done
fi


# 1. Upload a local file to the server
echo "[START]==================================== Upload the local file"
echo "Local file info:"
ls -al "$LOCAL_FILE"
if remote_execute "[ -f \"$REMOTE_UPLOAD_FILE\" ]"; then
  ask "The remote file '$REMOTE_UPLOAD_FILE' already exists. Do you want to overwrite it with '$LOCAL_FILE'? (y/n): "
else
  ask "Do you want to upload '$LOCAL_FILE' to '$REMOTE_UPLOAD_FILE'? (y/n): "
fi
sshpass -p "$REMOTE_PWD" rsync -avz "$LOCAL_FILE" "$LOGIN_USER@$REMOTE_HOST:$REMOTE_UPLOAD_FILE"
echo
echo "Upload completed, Print the remote uploaded file '$REMOTE_UPLOAD_FILE'"
remote_execute "ls -al $REMOTE_UPLOAD_FILE"
ask "Is the local file successfully uploaded? (y/n): "
echo "[END  ]==================================== Upload the local file"
echo

# 2. Back up the server file
echo "[START]==================================== Backup the server file"
# Check if the remote file exists
if ! remote_execute "[ -f \"$REMOTE_FILE\" ]"; then
  echo "[ERROR] Remote file does not exist: $REMOTE_FILE"
  echo "Aborting script."
  exit 1
fi

echo "Remote back up file info:"
remote_execute "ls -al $REMOTE_FILE"
ask "Do you want backup remote file '$REMOTE_FILE' to '$REMOTE_BACKUP_FILE'? (y/n): "
remote_execute "cp $REMOTE_FILE $REMOTE_BACKUP_FILE -f"
echo
echo "Backup completed, Print the remote backup file: $REMOTE_BACKUP_FILE"
remote_execute "ls -al $REMOTE_BACKUP_FILE"
ask "Is the server file successfully backed up? (y/n): "
echo "[END  ]==================================== Backup the server file"
echo

# 3. Overwrite the server files with the local file
echo "[START]==================================== Overwrite the server file"
echo "Remote source file info:"
remote_execute "ls -al $REMOTE_UPLOAD_FILE"
ask "Do you want overwrite the remote file '$REMOTE_FILE' by the uploaded file '$REMOTE_UPLOAD_FILE'? (y/n): "
remote_execute "cp $REMOTE_UPLOAD_FILE $REMOTE_FILE -f"
echo
echo "Overwrite completed, Print the remote overwritten file:"
remote_execute "ls -al $REMOTE_FILE"
#ask "Is the server file successfully overwritten? (y/n): "
echo "[END  ]==================================== Overwrite the server file"

# You can add post-execution commands here once all steps are complete.

# Do something