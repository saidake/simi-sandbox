# Table of Contents
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Functionalities](#functionalities)
  - [scripts/cpfiles.sh](#scriptscpfilessh)
  - [scripts/exec.sh](#scriptsexecsh)
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

## [scripts/exec.sh](./scripts/exec.sh)
This script executes a local bash file on the remote server without copying it.
* The first parameter of this Bash script is a local Bash file, which will be
executed directly on the remote server. The working path defaults to the user home.

![](./docs/assets/scripts/exec.svg)

