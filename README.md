# Table of Contents
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Functionalities](#functionalities)
  - [scripts/cpfiles.sh](#scriptscpfilessh)
  - [scripts/execr.sh](#scriptsexecrsh)
  - [scripts/patchr.sh](#scriptspatchrsh)
# Introduction
**Simi Sandbox** is a project to help transfer files, execute commands, and install databases or dependencies on remote servers.
# Functionalities
## [scripts/cpfiles.sh](./scripts/cpfiles.sh)

This script automates uploading specific files or directories from `scripts/AAA/assets`
to a remote server.
* Only files or folders listed in `scripts/AAA/config/path-mapping.properties` will be transferred.
* Server credentials are defined in `scripts/AAA/config/server.sh`, and each entry is mapped
to a target directory on the remote server.
* Each overwrite operation prompts a confirmation warning to ensure safety, unless `SILENT=true` is set.
* The script uses SCP or rsync for secure transfer and can optionally overwrite
existing files/directories on the remote side.

![](./docs/assets/scripts/cpfiles.svg)

## [scripts/execr.sh](./scripts/execr.sh)
This script executes a local bash file on the remote server without copying it.
* The first parameter of this Bash script is a local Bash file, which will be
executed directly on the remote server. The working path defaults to the user home.

![](./docs/assets/scripts/execr.svg)


## [scripts/patchr.sh](./scripts/patchr.sh)
This script safely patches a remote file on a server using one of two modes:
  1. Upload a local file and replace a target remote file.
  2. Recover the original remote file from a backup.

Steps (in patch mode):
  1. Upload a local file (`LOCAL_FILE`) to a temporary location (`REMOTE_UPLOAD_FILE`) on the remote server.
  2. Backup the target remote file (`REMOTE_FILE`) to a backup path (`REMOTE_BACKUP_FILE`).
  3. Overwrite the remote target file (`REMOTE_FILE`) with the uploaded file.

![](./docs/assets/scripts/patchr.svg)
