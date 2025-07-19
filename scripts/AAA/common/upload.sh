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

[[ -n "$_UPLOAD_SH_INCLUDED" ]] && return
_UPLOAD_SH_INCLUDED=1

source "$ROOT/AAA/common/functions.sh"

upload_file_or_dir_to_dir() {
  local source="$1"
  local remote_dir="$2"
  local use_rsync="$3"
  local silent="$4"

  absolute_remote_dir=$(resolve_remote_path "$remote_dir")

  if [[ ! -e "$source" ]]; then
    echo "[ERROR] Source '$source' does not exist." >&2
    exit 1
  fi

  if remote_file_exists "$absolute_remote_dir"; then
    echo "[ERROR] Remote path '$remote_dir' is a file, not a directory." >&2
    exit 1
  fi

  if ! remote_dir_exists "$absolute_remote_dir"; then
    echo "[INFO] Remote directory '$remote_dir' does not exist. Creating it."
    remote_execute "mkdir -p \"$absolute_remote_dir\""
  fi

  if ! remote_execute "[[ -d \"$absolute_remote_dir\" ]]" ; then
    echo "[ERROR] Remote destination '$remote_dir' is not a directory." >&2
    exit 1
  fi

  if [[ -d "$source" ]]; then
    echo "[INFO] Uploading contents of directory '$source' to '$remote_dir' ..."
    for item in "$source"/*; do
      local base_item
      base_item=$(basename "$item")

      if remote_execute "[[ -e \"$absolute_remote_dir/$base_item\" ]]"; then
        ask "$silent" "[WARN] '$base_item' already exists in '$remote_dir'. Overwrite? (y/n): "
      fi

      if [[ "$use_rsync" == true ]]; then
        sshpass -p "$REMOTE_PWD" rsync -avz -e "ssh -p $REMOTE_SSH_PORT" "$item" "$REMOTE_USER@$REMOTE_HOST:$absolute_remote_dir"
      else
        sshpass -p "$REMOTE_PWD" scp -r -P "$REMOTE_SSH_PORT" "$item" "$REMOTE_USER@$REMOTE_HOST:$absolute_remote_dir"
      fi

      if [[ $? -ne 0 ]]; then
        echo "[ERROR] Failed to upload '$item' to '$remote_dir'." >&2
        exit 1
      else
        echo "[INFO] Successfully uploaded '$item' to '$remote_dir'."
      fi
    done

  elif [[ -f "$source" ]]; then
    local base_file
    base_file=$(basename "$source")

    if remote_execute "[[ -e \"$absolute_remote_dir/$base_file\" ]]"; then
      ask "$silent" "[WARN] '$base_file' already exists in '$remote_dir'. Overwrite? (y/n): "
    fi

    echo "[INFO] Uploading file '$source' to '$remote_dir' ..."
    if [[ "$use_rsync" == true ]]; then
      sshpass -p "$REMOTE_PWD" rsync -avz -e "ssh -p $REMOTE_SSH_PORT" "$source" "$REMOTE_USER@$REMOTE_HOST:$absolute_remote_dir"
    else
      sshpass -p "$REMOTE_PWD" scp -P "$REMOTE_SSH_PORT" "$source" "$REMOTE_USER@$REMOTE_HOST:$absolute_remote_dir"
    fi

    if [[ $? -ne 0 ]]; then
      echo "[ERROR] Failed to upload '$source' to '$remote_dir'." >&2
      exit 1
    else
      echo "[INFO] Successfully uploaded '$source' to '$remote_dir'."
    fi

  else
    echo "[ERROR] Unsupported source type: $source" >&2
    exit 1
  fi
}


upload_file_to_file() {
  local local_file="$1"
  local remote_file="$2"
  local use_rsync="$3"
  local silent="$4"

  if [[ ! -f "$local_file" ]]; then
    echo "[ERROR] Local file '$local_file' does not exist or is not a regular file." >&2
    exit 1
  fi

  local absolute_remote_file
  absolute_remote_file="$(resolve_remote_path "$remote_file")"

  if remote_file_exists "$absolute_remote_file"; then
    ask "$silent" "[WARN] Remote file '$remote_file' already exists. Overwrite? (y/n): "
  else
    local remote_dir
    remote_dir="$(dirname "$absolute_remote_file")"
    if ! remote_dir_exists "$remote_dir"; then
      echo "[INFO] Remote directory '$remote_dir' does not exist. Creating it."
      remote_execute "mkdir -p \"$remote_dir\""
    fi
  fi

  echo "[INFO] Uploading file '$local_file' to remote '$remote_file' ..."
  if [[ "$use_rsync" == true ]]; then
    sshpass -p "$REMOTE_PWD" rsync -avz -e "ssh -p $REMOTE_SSH_PORT" "$local_file" "$REMOTE_USER@$REMOTE_HOST:$absolute_remote_file"
  else
    sshpass -p "$REMOTE_PWD" scp -P "$REMOTE_SSH_PORT" "$local_file" "$REMOTE_USER@$REMOTE_HOST:$absolute_remote_file"
  fi

  if [[ $? -ne 0 ]]; then
    echo "[ERROR] Failed to upload '$local_file' to '$remote_file'." >&2
    exit 1
  else
    echo "[INFO] Successfully uploaded '$local_file' to '$remote_file'."
  fi
}
