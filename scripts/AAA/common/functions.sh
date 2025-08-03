#!/bin/bash
#
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
#
# Author: Craig Brown
# Since: 1.2.0
# Date: July 17, 2025
# ************************************************************************************

[[ -n "$_FUNCTIONS_SH_INCLUDED" ]] && return
_FUNCTIONS_SH_INCLUDED=1

check_required_env_vars() {
  local message="$1"
  shift
  local vars=("$@")
  local missing_vars=()

  for var_name in "${vars[@]}"; do
    if [[ -z "${!var_name}" ]]; then
      missing_vars+=("$var_name")
    fi
  done

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo "[ERROR] $message" >&2
    echo "Missing environment variables: ${missing_vars[*]}" >&2
    exit 1
  fi
}

check_required_env_vars \
  "Please source config/global.sh before running this script." \
  ROOT
check_required_env_vars \
  "Please source config/server.sh to configure server properties before running this script." \
  REMOTE_HOST \
  REMOTE_SSH_PORT \
  REMOTE_USER \
  REMOTE_PWD

check_ssh_connection(){
  # Check if port is open
  if ! timeout 5 bash -c "cat < /dev/null > /dev/tcp/$REMOTE_HOST/$REMOTE_SSH_PORT" 2>/dev/null; then
    echo "[ERROR] Cannot connect to $REMOTE_HOST on port $REMOTE_SSH_PORT. Aborting script."
    exit 3
  fi
}

trust_host() {
  local ssh_dir="$HOME/.ssh"
  local known_hosts_file="$ssh_dir/known_hosts"
  local search_entry

  # Check ~/.ssh directory
  if [ ! -d "$ssh_dir" ]; then
    echo "[INFO] ~/.ssh does not exist. Skipping trust setup for $REMOTE_HOST."
    return
  fi

  # Determine search_entry format for known_hosts
  if [[ "$REMOTE_SSH_PORT" == "22" ]]; then
    search_entry="$REMOTE_HOST"
  else
    search_entry="[$REMOTE_HOST]:$REMOTE_SSH_PORT"
  fi

  # Check if already trusted
  if grep -qF "$search_entry" "$known_hosts_file" 2>/dev/null; then
    echo "[INFO] Host $search_entry already trusted, skipping."
    return
  fi


  echo "[INFO] Trusting $search_entry ..."
  ssh-keygen -R "$search_entry" > /dev/null 2>&1 || true
  if ! ssh-keyscan -p "$REMOTE_SSH_PORT" "$REMOTE_HOST" >> "$known_hosts_file" 2>/dev/null; then
    echo "[ERROR] ssh-keyscan failed for $search_entry $known_hosts_file"
    exit 2
  fi
}



# Choice function to interact with the user
ask() {
  local silent="$1"
  shift
  local prompt="${1:-Are you sure? (y/n): }"

  if [[ "$silent" != true && "$silent" != false && -n "$silent" ]]; then
    echo "[ERROR] Invalid value for silent: '$silent'. Must be 'true' or 'false'." >&2
    exit 2
  fi

  if [[ "$silent" == true ]]; then
    return 0
  fi

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
  sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "$1"
}

check_sshpass_installed() {
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "[ERROR] sshpass is NOT installed on local machine."
    exit 2
  fi

  if ! sshpass -p "$REMOTE_PWD" ssh -p "$REMOTE_SSH_PORT" "$REMOTE_USER@$REMOTE_HOST" "command -v sshpass >/dev/null 2>&1"; then
    echo "[ERROR] sshpass is NOT installed on remote server $REMOTE_USER@$REMOTE_HOST."
    exit 2
  fi
}

resolve_remote_path() {
  local raw_path="$1"
  remote_execute "echo $raw_path"
}

remote_dir_exists() {
  remote_execute "[ -d \"$1\" ]"
}

remote_file_exists() {
  remote_execute "[ -f \"$1\" ]"
}