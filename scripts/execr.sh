#!/bin/bash
# Copyright 2012-2025 the original author or authors.
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
# This script executes a local bash file on the remote server without copying it.
# The first parameter of this Bash script is a local Bash file, which will be
# executed directly on the remote server. The working path defaults to the user home.
#
# Note: This script uses your provided credentials to switch to the **root** user in order to
# execute commands with **sudo** privileges.
#
# Prerequisites:
#   1. `sshpass` is installed on both local and the remote servers.
#   2. Configure variables in `scripts/AAA/config/server.sh`:
#        - REMOTE_HOST
#        - REMOTE_USER
#        - REMOTE_SSH_PORT (default: 22)
#        - REMOTE_PWD
#
# Examples (run directly for easy start, using default settings):
#   * ./scripts/execr.sh ./scripts/AAA/assets/example-bash.sh
#
#      Execute the bash file `./scripts/AAA/assets/example-bash.sh` on your remote server.
#
# Usage:
#   * ./scripts/exec.sh <local-bash-file-path>
#
# Script Options (variables in this script):
#   * USE_RSYNC    : (true/false) Use 'rsync' for uploading instead of 'scp'.
#
#   * SILENT       : (true/false) If true, disables all confirmation prompts (auto-approve).
#   * LOCAL_BASH_FILE       : Local bash file to execute
#   * REMOTE_TMP_BASH_FILE  : The local bash script will be uploaded to this path on the remote server.

# Global Env:
#   * ROOT : The absolute path of scripts directory.
#
# Author: Craig Brown
# Since: 1.1.0
# Date: Oct 4, 2024
# ************************************************************************************
source "$(dirname "${BASH_SOURCE[0]}")/AAA/config/global.sh"

# ================================================================== Required Configurations
# Import global environment variables
source "$ROOT/AAA/config/server.sh"

# ================================================================== Default Configurations
LOCAL_BASH_FILE="$1"     # Local bash file to execute
REMOTE_TMP_BASH_FILE="/tmp/execr-remote-execution.sh"  # The local bash script will be uploaded to this path on the remote server

SILENT=false
USE_RSYNC=false
# ================================================================== Validate Input
source "$ROOT/AAA/common/functions.sh"
source "$ROOT/AAA/common/upload.sh"
check_ssh_connection
trust_host
check_sshpass_installed

if [[ -z "$LOCAL_BASH_FILE" ]]; then
  echo "[ERROR] No bash script file provided. Please pass the script file path as an argument."
  exit 1
fi

if [[ ! -f "$LOCAL_BASH_FILE" ]]; then
  echo "[ERROR] File does not exist: $LOCAL_BASH_FILE"
  exit 1
fi

# ================================================================== Execute Remotely
echo "[INFO] Executing '$LOCAL_BASH_FILE' on remote host $REMOTE_USER@$REMOTE_HOST..."

# Use sshpass to pass the password
#remote_execute "cd $REMOTE_WORK_PATH && bash -l -c 'bash -s'" < "$LOCAL_BASH_FILE"
#remote_execute "cd $REMOTE_WORK_PATH && echo \"$REMOTE_PWD\" | sudo -S bash -l -c 'bash -s'" < "$LOCAL_BASH_FILE"
#remote_execute "cd $REMOTE_WORK_PATH && sudo -S bash -l -s" < "$LOCAL_BASH_FILE"
#remote_execute "cd $REMOTE_WORK_PATH && echo \"$REMOTE_PWD\" | sudo -S bash -l -s" < "$LOCAL_BASH_FILE"
#remote_execute "cd $REMOTE_WORK_PATH && echo \"$REMOTE_PWD\" | sudo -S bash -l -s" < "$LOCAL_BASH_FILE"
#sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" << EOF
#echo "$REMOTE_PWD" | sudo -S pwd
#pwd
#EOF
#remote_execute "cd $REMOTE_WORK_PATH && echo \"$REMOTE_PWD\" | sudo -S bash -l -s" < "$LOCAL_BASH_FILE"
upload_file_to_file "$LOCAL_BASH_FILE" "$REMOTE_TMP_BASH_FILE" $USE_RSYNC $SILENT
#remote_execute "echo \"$REMOTE_PWD\" | sudo -S bash $REMOTE_TMP_BASH_FILE && rm -f $REMOTE_TMP_BASH_FILE"
remote_execute "echo \"$REMOTE_PWD\" | sudo -S bash -c 'echo; echo \"[INFO] Remote execution output: \"; bash \"$REMOTE_TMP_BASH_FILE\"; rm -f \"$REMOTE_TMP_BASH_FILE\"'"
