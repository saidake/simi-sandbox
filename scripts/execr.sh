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
# This script executes a local bash file on the remote server without copying it.
# The first parameter of this Bash script is a local Bash file, which will be
# executed directly on the remote server. The working path defaults to the user home.
#
# Prerequisites:
#   1. Create your custom bash file for remote execution (e.g. ./AAA/assets/example-bash.sh).
#   2. Configure variables in `scripts/AAA/config/server.sh`:
#        - REMOTE_HOST
#        - REMOTE_USER
#        - REMOTE_SSH_PORT (default: 22)
#        - REMOTE_PWD
#
# Usage:
#   * ./exec.sh <local-bash-file-path>
#
# Example:
#   * ./execr.sh ./AAA/assets/example-bash.sh
#
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
# Example:
# REMOTE_HOST='192.168.127.131'
# REMOTE_SSH_PORT='22'
# REMOTE_USER='test99'
# REMOTE_PWD='testpwd'

# ================================================================== Default Configurations
REMOTE_WORK_PATH='~'  # Remote working directory
LOCAL_BASH_PATH="$1"     # Local bash file to execute

# ================================================================== Validate Input
source "$ROOT/AAA/common/functions.sh"
trust_host

if [[ -z "$LOCAL_BASH_PATH" ]]; then
  echo "[ERROR] No bash script file provided. Please pass the script file path as an argument."
  exit 1
fi

if [[ ! -f "$LOCAL_BASH_PATH" ]]; then
  echo "[ERROR] File does not exist: $LOCAL_BASH_PATH"
  exit 1
fi

# ================================================================== Execute Remotely
echo "[INFO] Executing '$LOCAL_BASH_PATH' on remote host $REMOTE_USER@$REMOTE_HOST..."

# Use sshpass to pass the password
remote_execute "cd $REMOTE_WORK_PATH && bash -l -c 'bash -s'" < "$LOCAL_BASH_PATH"
