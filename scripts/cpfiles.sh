#!/bin/bash
# ************************************************************************************
# This script automates uploading specific files or directories from `scripts/assets`
# to a remote server.
#
# Only files or folders listed in `scripts/config/path-mapping.properties` will be transferred.
# Server credentials are defined in `scripts/config/server.sh`, and each entry is mapped
# to a target directory on the remote server.
#
# Each overwrite operation prompts a confirmation warning to ensure safety, unless `SILENT=true` is set.
#
# The script uses SCP or rsync for secure transfer and can optionally overwrite
# existing files/directories on the remote side.
#
# Prerequisites:
#   1. Put your files or folders in the `scripts/assets` folder.
#   2. Define path mappings in `scripts/config/path-mapping.properties`.
#   3. Configure variables in `scripts/config/server.sh`:
#        - REMOTE_HOST
#        - REMOTE_USER
#        - REMOTE_SSH_PORT (default: 22)
#        - REMOTE_PWD
#
# Usage:
#   ./cpfiles.sh
#
# Script Options (variables inside this script):
#   IS_OVERWRITE : (true/false) Whether to overwrite existing remote files/directories.
#                  When true, script prompts before deleting remote files/dirs unless SILENT=true.
#
#   USE_RSYNC    : (true/false) Use 'rsync' for uploading instead of 'scp'.
#
#   SILENT       : (true/false) If true, disables all confirmation prompts (auto-approve).
#
# Author: Craig Brown
# Since: 1.1.0
# Date: July 8, 2025
# ************************************************************************************

# ================================================================== Required Configurations
# Import global environment variables
source ./config/server.sh
# Customize the values if needed
# REMOTE_HOST='192.168.127.131'
# REMOTE_SSH_PORT='22'
# REMOTE_USER='test99'
# REMOTE_PWD='testpwd'

# ================================================================== Default Configurations
# Overwrite the old file or folder.
IS_OVERWRITE=true
# Use 'rsync' instead of 'scp'
USE_RSYNC=true
# Ask warning messages
SILENT=false
# Load file-to-directory mappings from properties file
properties_file="./config/path-mapping.properties"
# Assets
assets_directory="./assets"

# ================================================================== Load Mapping File
declare -A file_mappings

trust_host() {
  echo "[INFO] Trusting $REMOTE_HOST:$REMOTE_SSH_PORT"
  ssh-keygen -R "$REMOTE_HOST" > /dev/null 2>&1
  ssh-keyscan -p "$REMOTE_SSH_PORT" "$REMOTE_HOST" >> ~/.ssh/known_hosts 2>/dev/null
}
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

resolve_remote_path() {
  local raw_path="$1"
  local resolved_path
  resolved_path=$(sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "echo $raw_path")
  echo "$resolved_path"
}

load_properties() {
    if [[ ! -f "$properties_file" ]]; then
        echo "[ERROR] Mapping file not found: $properties_file"
        exit 1
    fi

    while IFS='=' read -r local_path target_path; do
        # echo "Read line: local_path='$local_path', target_path='$target_path'" # Debug output
        local_path=$(echo "$local_path" | xargs)
        target_path=$(echo "$target_path" | xargs)
        [[ -n "$local_path" && -n "$target_path" ]] && file_mappings["$local_path"]="$target_path"
    done < "$properties_file"
}

remote_dir_exists() {
  sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "[ -d \"$1\" ]"
}

remote_file_exists() {
  sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "[ -f \"$1\" ]"
}

prepare_remote_directory() {
  local remote_dir="$1"
  if remote_dir_exists "$remote_dir"; then
    if [[ "$IS_OVERWRITE" == true ]]; then
      echo "[INFO] Overwrite the existed old directory: $remote_dir"
      ask "[WARNING] Are you sure to overwrite the remote directory $remote_dir ? (y/n): "
      sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "rm -rf \"$remote_dir\"/*"
    fi
  else
    echo "[INFO] Remote directory $remote_dir does not exist. Creating it."
    sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p \"$remote_dir\""
  fi
}

remove_remote_file_if_exists() {
  local remote_file="$1"
  if remote_file_exists "$remote_file"; then
    echo "[INFO] Overwrite the existed old file: $remote_file"
    ask "[WARNING] Are you sure to overwrite the remote file $remote_file ? (y/n): "
    sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "rm -f \"$remote_file\""
  fi
}

do_upload() {
  local source="$1"
  local dest="$2"
  local is_dir="$3"  # true or false

  if [[ "$USE_RSYNC" == true ]]; then
    if [[ "$is_dir" == true ]]; then
      sshpass -p "$REMOTE_PWD" rsync -avz -e "ssh -p $REMOTE_SSH_PORT" "$source/" "$REMOTE_USER@$REMOTE_HOST:$dest"
    else
      sshpass -p "$REMOTE_PWD" rsync -avz -e "ssh -p $REMOTE_SSH_PORT" "$source" "$REMOTE_USER@$REMOTE_HOST:$dest"
    fi
  else
    if [[ "$is_dir" == true ]]; then
      sshpass -p "$REMOTE_PWD" scp -r -P "$REMOTE_SSH_PORT" "$source/"* "$REMOTE_USER@$REMOTE_HOST:$dest"
    else
      sshpass -p "$REMOTE_PWD" scp -P "$REMOTE_SSH_PORT" "$source" "$REMOTE_USER@$REMOTE_HOST:$dest"
    fi
  fi
}

upload_item() {
  local local_path="$1"
  local remote_raw_path="$2"
  remote_dir=$(resolve_remote_path "$remote_raw_path")
  trust_host

  if [[ -d "$local_path" ]]; then
    prepare_remote_directory "$remote_dir"
    echo "[INFO] Uploading directory '$local_path' to '$remote_dir'"
    do_upload "$local_path" "$remote_dir" true
  elif [[ -f "$local_path" ]]; then
    file_name=$(basename "$local_path")
    remote_file="$remote_dir/$file_name"

    if [[ "$IS_OVERWRITE" == true ]]; then
      remove_remote_file_if_exists "$remote_file"
    fi

    echo "[INFO] Uploading file '$local_path' to '$remote_dir'"
    do_upload "$local_path" "$remote_dir" false
  else
    echo "[WARN] Skipping unrecognized path: $local_path"
  fi
}


upload_files() {
  echo "[INFO] Starting upload process..."
  for item in "${!file_mappings[@]}"; do
    local_path="$assets_directory/$item"
    remote_dir="${file_mappings[$item]}"
    # echo "folder or file: $local_path"

    if [[ -e "$local_path" ]]; then
      upload_item "$local_path" "$remote_dir"
    else
      echo "[WARN] '$item' not found in assets. Skipping."
    fi
  done
  echo "[INFO] Upload complete."
}

# ================================================================== Run
load_properties
upload_files