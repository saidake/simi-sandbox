#!/bin/bash
#
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
#
# Author: Craig Brown
# Since: 1.2.0
# Date: July 17, 2025
# ************************************************************************************

[[ -n "$_FUNCTIONS_SH_INCLUDED" ]] && return
_FUNCTIONS_SH_INCLUDED=1

check_required_env_vars() {
  local vars=("$@")

  for var_name in "${vars[@]}"; do
    if [[ -z "${!var_name}" ]]; then
      echo "[ERROR] Required environment variable '$var_name' is not set. Please source config/server.sh before this script." >&2
      exit 1
    fi
  done
}
check_required_env_vars ROOT REMOTE_HOST REMOTE_SSH_PORT REMOTE_USER REMOTE_PWD

trust_host() {
  local known_hosts_file=~/.ssh/known_hosts
  local search_entry

  if [[ "$REMOTE_SSH_PORT" == "22" ]]; then
    search_entry="$REMOTE_HOST"
  else
    search_entry="[$REMOTE_HOST]:$REMOTE_SSH_PORT"
  fi

  if grep -qF "$search_entry" "$known_hosts_file"; then
    echo "[INFO] Host $search_entry already trusted, skipping."
  else
    echo "[INFO] Trusting $search_entry ..."
    ssh-keygen -R "$REMOTE_HOST" -p "$REMOTE_SSH_PORT" > /dev/null 2>&1
    ssh-keyscan -p "$REMOTE_SSH_PORT" "$REMOTE_HOST" >> "$known_hosts_file" 2>/dev/null
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