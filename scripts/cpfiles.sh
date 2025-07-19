#!/bin/bash
# Copyright 2022-2025 the original author or authors.
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
########################################################################################
# This script automates uploading specific files or directories from `scripts/AAA/assets`
# to a remote server.
#
# Only files or folders listed in `scripts/AAA/config/path-mapping.properties` will be transferred.
# Server credentials are defined in `scripts/AAA/config/server.sh`, and each entry maps
# to a target directory on the remote server.
#
# Overwrite operations prompt for confirmation to ensure safety, unless SILENT=true is set.
#
# Transfers use SCP or rsync securely, with optional overwrite of existing remote files/dirs.
#
# Prerequisites:
#   1. Configure server variables in `scripts/AAA/config/server.sh`:
#        - REMOTE_HOST
#        - REMOTE_USER
#        - REMOTE_SSH_PORT (default: 22)
#        - REMOTE_PWD
#
# Examples (run directly for easy start, using default settings):
#   * ./scripts/cpfiles.sh
#
#       Copies `example1.txt` to the test server’s home directory (~),
#       and copies `example2.txt` and `example3.txt` from `scripts/AAA/assets/exampledir` to the remote directory
#       `targetdir` on the test server.
#
# Usage:
#   * ./scripts/cpfiles.sh [<env.sh>]
#
#      You can define script options in a specified `env.sh` to override the default options in this script.
#
# Script Options (variables in this script):
#   * USE_RSYNC    : (true/false) Use 'rsync' for uploading instead of 'scp'.
#
#   * SILENT       : (true/false) If true, disables all overwrite confirmation prompts (auto-approve).
#   * PROPERTIES_FILE   : Copies the folder contents or files corresponding to the keys in the properties file
#       to the remote directories specified by the values.
#   * ASSETS_ROOT       : The base directory where the relative paths (keys) from PROPERTIES_FILE are located.
#
# Global Environment Variables:
#   * ROOT : The absolute path of the scripts directory.
#
# Author: Craig Brown
# Since : 1.1.0
# Date  : July 8, 2025
########################################################################################
source "$(dirname "${BASH_SOURCE[0]}")/AAA/config/global.sh"

# ================================================================== Required Configurations
# Import global environment variables
source "$ROOT/AAA/config/server.sh"
# Example (in server.sh):
# REMOTE_HOST='192.168.127.131'
# REMOTE_SSH_PORT='22'
# REMOTE_USER='test99'
# REMOTE_PWD='testpwd'

# ================================================================== Default Configurations
# Use 'rsync' instead of 'scp'
USE_RSYNC=false
# Ask warning messages
SILENT=false
# Load file-to-directory mappings from properties file
PROPERTIES_FILE="$ROOT/AAA/config/path-mapping.properties"
# Assets
ASSETS_ROOT="$ROOT/AAA/assets"

# ================================================================== Functions
if [[ -n "$1" ]]; then
  if [[ -f "$1" ]]; then
    echo "[INFO] Loading override environment variables from $1 ..."
    # shellcheck disable=SC1090
    source "$1"
  else
    echo "[ERROR] Environment file '$1' not found."
    exit 1
  fi
fi


source "$ROOT/AAA/common/functions.sh"
source "$ROOT/AAA/common/property_transfer.sh"

# ================================================================== Logic
trust_host
upload_files_by_properties "$PROPERTIES_FILE" "$ASSETS_ROOT" $USE_RSYNC $SILENT