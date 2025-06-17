#!/bin/bash
# Copyright 2012-2024 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ************************************************************************************
# This script automates uploading specific files or directories from `scripts/AAA/assets`
# to a remote server.
#
# Only files or folders listed in `scripts/AAA/config/path-mapping.properties` will be transferred.
# Server credentials are defined in `scripts/AAA/config/server.sh`, and each entry is mapped
# to a target directory on the remote server.
#
# Each overwrite operation prompts a confirmation warning to ensure safety, unless `SILENT=true` is set.
#
# The script uses SCP or rsync for secure transfer and can optionally overwrite
# existing files/directories on the remote side.
#
# Prerequisites:
#   1. Put your files or folders in the `scripts/AAA/assets` folder.
#   2. Define path mappings in `scripts/AAA/config/path-mapping.properties`.
#   3. Configure variables in `scripts/AAA/config/server.sh`:
#        - REMOTE_HOST
#        - REMOTE_USER
#        - REMOTE_SSH_PORT (default: 22)
#        - REMOTE_PWD
#
# Usage:
#   * ./scripts/cpfiles.sh
#
# Example (with default options defined in this script):
#   * ./scripts/cpfiles.sh
#
# Script Options (variables inside this script):
#   * IS_OVERWRITE : (true/false) Whether to overwrite existing remote files/directories.
#                  When true, script prompts before deleting remote files/dirs unless SILENT=true.
#
#   * USE_RSYNC    : (true/false) Use 'rsync' for uploading instead of 'scp'.
#
#   * SILENT       : (true/false) If true, disables all confirmation prompts (auto-approve).
#
# Global Env:
#   * ROOT : The absolute path of scripts directory.
#
# Author: Craig Brown
# Since: 1.1.0
# Date: July 8, 2025
# ************************************************************************************
# shellcheck disable=SC2034
source "$(dirname "${BASH_SOURCE[0]}")/AAA/config/global.sh"

# ================================================================== Required Configurations
# Import global environment variables
source "$ROOT/AAA/config/server.sh"
# Customize the values if needed
# REMOTE_HOST='192.168.127.131'
# REMOTE_SSH_PORT='22'
# REMOTE_USER='test99'
# REMOTE_PWD='testpwd'

# ================================================================== Default Configurations
# Overwrite the old file or folder.
IS_OVERWRITE=true
# Use 'rsync' instead of 'scp'
USE_RSYNC=false
# Ask warning messages
SILENT=false
# Load file-to-directory mappings from properties file
properties_file="$ROOT/AAA/config/path-mapping.properties"
# Assets
assets_directory="$ROOT/AAA/assets"

# ================================================================== Functions
source "$ROOT/AAA/common/functions.sh"
source "$ROOT/AAA/common/upload.sh"
declare -A file_mappings

load_properties() {
    if [[ ! -f "$properties_file" ]]; then
        echo "[ERROR] Mapping file not found '$properties_file'"
        exit 1
    fi

    while IFS='=' read -r local_path target_path; do
        # echo "Read line: local_path='$local_path', target_path='$target_path'" # Debug output
        local_path=$(echo "$local_path" | xargs)
        target_path=$(echo "$target_path" | xargs)
        [[ -n "$local_path" && -n "$target_path" ]] && file_mappings["$local_path"]="$target_path"
    done < "$properties_file"
}

upload_files() {
  echo "[INFO] Starting upload process..."
  for item in "${!file_mappings[@]}"; do
    local_path="$assets_directory/$item"
    remote_dir="${file_mappings[$item]}"
    # echo "folder or file: $local_path"

    if [[ -e "$local_path" ]]; then
      upload_file_or_dir_to_dir "$local_path" "$remote_dir"
    else
      echo "[WARN] '$item' not found in assets. Skipping."
    fi
  done
  echo "[INFO] Upload complete."
}

# ================================================================== Logic
trust_host
load_properties
upload_files