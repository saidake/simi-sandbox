# Table of Contents
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Functionalities](#functionalities)
  - [scripts/cpfiles.sh](#scriptscpfilessh)
  - [scripts/execr.sh](#scriptsexecrsh)
  - [scripts/patchr.sh](#scriptspatchrsh)
# Introduction
**Simi Sandbox** is a toolkit for transferring files, executing commands, and managing remote servers — including installing databases and dependencies.
# Functionalities
## [scripts/cpfiles.sh](./scripts/cpfiles.sh)
![](./docs/assets/scripts/cpfiles.svg)  
 This script automates uploading specific files or directories from `scripts/AAA/assets`
 to a remote server.

 Only files or folders listed in `scripts/AAA/config/path-mapping.properties` will be transferred.
 Server credentials are defined in `scripts/AAA/config/server.sh`, and each entry is mapped
 to a target directory on the remote server.

 Each overwrite operation prompts a confirmation warning to ensure safety, unless `SILENT=true` is set.

 The script uses SCP or rsync for secure transfer and can optionally overwrite
 existing files/directories on the remote side.

 Prerequisites:
   1. Put your files or folders in the `scripts/AAA/assets` folder.
   2. Define path mappings in `scripts/AAA/config/path-mapping.properties`.
   3. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD

 Usage:
   ./cpfiles.sh

 Script Options (variables inside this script):
   * IS_OVERWRITE : (true/false) Whether to overwrite existing remote files/directories.
                  When true, script prompts before deleting remote files/dirs unless SILENT=true.

   * USE_RSYNC    : (true/false) Use 'rsync' for uploading instead of 'scp'.

   * SILENT       : (true/false) If true, disables all confirmation prompts (auto-approve).

 Global Env:
   * ROOT : The absolute path of scripts directory.


## [scripts/execr.sh](./scripts/execr.sh)
![](./docs/assets/scripts/execr.svg)  
 This script executes a local bash file on the remote server without copying it.
 The first parameter of this Bash script is a local Bash file, which will be
 executed directly on the remote server. The working path defaults to the user home.

 Prerequisites:
   1. Create your custom bash file for remote execution (e.g. ./AAA/assets/example-bash.sh).
   2. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD

 Usage:
   * ./exec.sh <local-bash-file-path>

 Example:
   * ./execr.sh ./AAA/assets/example-bash.sh

 Global Env:
   * ROOT : The absolute path of scripts directory.

## [scripts/patchr.sh](./scripts/patchr.sh)
![](./docs/assets/scripts/patchr.svg)  
 This script safely patches a remote file on a server using one of two modes:
   1. Upload a local file and replace a target remote file.
   2. Recover the original remote file from a backup.

 Steps (in patch mode):
   1. Upload a local file (`LOCAL_FILE`) to a temporary location (`REMOTE_UPLOAD_FILE`) on the remote server.
   2. Backup the target remote file (`REMOTE_FILE`) to a backup path (`REMOTE_BACKUP_FILE`).
   3. Overwrite the remote target file (`REMOTE_FILE`) with the uploaded file.

 Steps (in recover mode):
   1. Overwrite the current remote file (`REMOTE_FILE`) with the backup (`REMOTE_BACKUP_FILE`).

 Script Options (variables inside this script):
   * LOCAL_FILE         : Path to the local file that will be uploaded.
   * REMOTE_UPLOAD_FILE : Remote file path where the local file will be uploaded.
   * REMOTE_FILE        : The original remote file to be backed up before overwriting.
   * REMOTE_BACKUP_FILE : Path where the backup of REMOTE_FILE will be stored.
   * USE_RSYNC          : (true/false) If true, use 'rsync' for uploading; otherwise use 'scp'.
   * SILENT             : (true/false) If true, suppresses all confirmation prompts (auto-approve).

 Prerequisites:
   1. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD

 Usage:
   * ./patchr.sh            # Patch remote file
   * ./patchr.sh recover    # Recover from backup

 Global Env:
   * ROOT : The absolute path of scripts directory.