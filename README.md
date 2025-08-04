# Table of Contents
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Core Scripts](#core-scripts)
  - [scripts/cpfiles.sh](#scriptscpfilessh)
  - [scripts/execr.sh](#scriptsexecrsh)
  - [scripts/patchr.sh](#scriptspatchrsh)
- [Environment Configuration Helper](#environment-configuration-helper)
  - [Docker and Docker Compose](#docker-and-docker-compose)
  - [AWS LocalStack](#aws-localstack)
# Introduction
**Simi Sandbox** is a developer-friendly toolkit for remote server management — enabling file transfer, command execution, and automated dependency setup.

# Core Scripts
## [scripts/cpfiles.sh](./scripts/cpfiles.sh)
![](./docs/assets/scripts/cpfiles.svg)  
This script automates uploading specific files or directories from `scripts/AAA/assets`
to a remote server.

Only files or folders listed in `scripts/AAA/config/path-mapping.properties` will be transferred.
Server credentials are defined in `scripts/AAA/config/server.sh`, and each entry maps
to a target directory on the remote server.

Overwrite operations prompt for confirmation to ensure safety, unless `SILENT=true` is set.

Transfers use SCP or rsync securely, with optional overwrite of existing remote files/dirs.

Prerequisites:
  1. `sshpass` is installed on both local and the remote servers.
  2. Configure server variables in `scripts/AAA/config/server.sh`:
       - REMOTE_HOST
       - REMOTE_USER
       - REMOTE_SSH_PORT (default: 22)
       - REMOTE_PWD

Examples (run directly for easy start, using default settings):
  * ./scripts/cpfiles.sh

      Copies `example1.txt` to the remote directory `~/examples`,
      and copies `example2.txt` and `example3.txt` from `scripts/AAA/assets/exampledir` to the remote directory
      `~/examples/targetdir` on the test server.
  * ./scripts/cpfiles.sh ./scripts/AAA/assets/example-env.sh

      Use the specified env configuration to copy `example2.txt` and `example3.txt` from `scripts/AAA/assets/exampledir` to the remote directory
      `~/examples/targetdir2` on the test server.

Usage:
  * ./scripts/cpfiles.sh [<env.sh>]

     You can define script options in a specified `env.sh` to override the default options in this script.

Script Options (variables in this script):
  * USE_RSYNC    : (true/false) Use `rsync` for uploading instead of `scp`.

  * SILENT       : (true/false) If true, disables all overwrite confirmation prompts (auto-approve).
  * PROPERTIES_FILE   : Copies the folder contents or files corresponding to the keys in the properties file
      to the remote directories specified by the values.
  * ASSETS_ROOT       : The base directory where the relative paths (keys) from PROPERTIES_FILE are located.

Global Environment Variables:
  * ROOT : The absolute path of the scripts directory.

## [scripts/execr.sh](./scripts/execr.sh)
![](./docs/assets/scripts/execr.svg)  
This script executes a local bash file on the remote server without copying it.
The first parameter of this Bash script is a local Bash file, which will be
executed directly on the remote server. The working path defaults to the user home.

Note: This script uses your provided credentials to switch to the **root** user in order to
execute commands with **sudo** privileges.

Prerequisites:
  1. `sshpass` is installed on both local and the remote servers.
  2. Configure variables in `scripts/AAA/config/server.sh`:
       - REMOTE_HOST
       - REMOTE_USER
       - REMOTE_SSH_PORT (default: 22)
       - REMOTE_PWD

Examples (run directly for easy start, using default settings):
  * ./scripts/execr.sh ./scripts/AAA/assets/example-bash.sh

     Execute the bash file `./scripts/AAA/assets/example-bash.sh` on your remote server.

Usage:
  * ./scripts/exec.sh <local-bash-file-path>

Script Options (variables in this script):
  * USE_RSYNC    : (true/false) Use 'rsync' for uploading instead of 'scp'.

  * SILENT       : (true/false) If true, disables all confirmation prompts (auto-approve).
  * LOCAL_BASH_FILE       : Local bash file to execute
  * REMOTE_TMP_BASH_FILE  : The local bash script will be uploaded to this path on the remote server.

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

Prerequisites:
  1. `sshpass` is installed on both local and the remote servers.
  2. Configure variables in `scripts/AAA/config/server.sh`:
       - REMOTE_HOST
       - REMOTE_USER
       - REMOTE_SSH_PORT (default: 22)
       - REMOTE_PWD
  3. Create a file `~/examples/example-patch-remote.txt` on your remote server for testing purposes.

Examples (run directly for easy start, using default settings):
  * ./scripts/patchr.sh

       Patch remote file `~/examples/example-patch-remote.txt` with the local file `scripts/AAA/assets/example-patch.txt`
  * ./scripts/patchr.sh recover

       Recover from backup

Usage:
  * ./scripts/patchr.sh

       Patch remote file
  * ./scripts/patchr.sh recover

       Recover from backup

Script Options (variables inside this script):
  * LOCAL_FILE         : Path to the local file that will be uploaded.
  * REMOTE_UPLOAD_FILE : Remote file path where the local file will be uploaded.
  * REMOTE_FILE        : The original remote file to be backed up before overwriting.
  * REMOTE_BACKUP_FILE : Path where the backup of REMOTE_FILE will be stored.

  * USE_RSYNC          : (true/false) If true, use 'rsync' for uploading; otherwise use 'scp'.
  * SILENT             : (true/false) If true, suppresses all confirmation prompts (auto-approve).

Global Env:
  * ROOT : The absolute path of scripts directory.

# Environment Configuration Helper
## Docker and Docker Compose
Instructions to install and configure Docker and Docker Compose on your system.

Prerequisites:
   1. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD

Commands: 
* `./scripts/execr.sh ./scripts/docker/install.sh`
  
  * Install Docker and Docker Compose.
    
    Example Success Output:
    ```
    ...
    [INFO] Docker installed successfully: Docker version 28.3.2, build 578ccf6
    ...
    [INFO] Docker Compose installed successfully: Docker Compose version v2.38.2
    [INFO] Installation complete.
    ```
## AWS LocalStack
A fully functional local AWS cloud stack for testing and development.

Prerequisites:
   1. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD
   2. **Docker** and **Docker Compose** have been installed (see [Docker and Docker Compose](#docker-and-docker-compose)).

Commands: 
* `./scripts/cpfiles.sh ./scripts/aws/env.sh`
  * Copy required files to the remote server.
* `./scripts/execr.sh ./scripts/aws/localstack-start.sh`
  * Start LocalStack Service.
* `./scripts/execr.sh ./scripts/aws/localstack-stop.sh`
  * Stop LocalStack Service.