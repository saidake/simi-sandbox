#!/bin/bash
# ************************************************************************************
# This script executes a local bash file on the remote server without copying it.
# The first parameter of this Bash script is a local Bash file, which will be
# executed directly on the remote server. The working path defaults to the user home.
#
# Prerequisites:
#   Modify the required configurations in the script with your own values.
#
# Usage:
#   ./exec.sh <local-bash-file-path>
#
# Example:
#   ./execr.sh ./AAA/assets/example-bash.sh
#
# Author: Craig Brown
# Since: 1.1.0
# Date: Oct 4, 2024
# ************************************************************************************

# ================================================================== Required Configurations
# Import global environment variables
source ./AAA/config/server.sh
# Example:
# REMOTE_HOST='192.168.127.131'
# REMOTE_SSH_PORT='22'
# REMOTE_USER='test99'
# REMOTE_PWD='testpwd'

# ================================================================== Default Configurations
remote_work_path='~'  # Remote working directory
exe_bash_path="$1"     # Local bash file to execute

# ================================================================== Validate Input
if [[ -z "$exe_bash_path" ]]; then
  echo "[ERROR] No bash script file provided. Please pass the script file path as an argument."
  exit 1
fi

if [[ ! -f "$exe_bash_path" ]]; then
  echo "[ERROR] File does not exist: $exe_bash_path"
  exit 1
fi

# ================================================================== Execute Remotely
echo "[INFO] Executing '$exe_bash_path' on remote host $REMOTE_USER@$REMOTE_HOST..."

# Use sshpass to pass the password
sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" \
  "cd $remote_work_path && bash -l -c 'bash -s'" < "$exe_bash_path"
