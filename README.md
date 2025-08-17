# Table of Contents
- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
- [Core Scripts](#core-scripts)
  - [scripts/cpfiles.sh](#scriptscpfilessh)
  - [scripts/execr.sh](#scriptsexecrsh)
  - [scripts/patchr.sh](#scriptspatchrsh)
- [Environment Configuration Helper](#environment-configuration-helper)
  - [Docker and Docker Compose](#docker-and-docker-compose)
    - [Installing on a Remote Linux Host](#installing-on-a-remote-linux-host)
  - [Docker Desktop](#docker-desktop)
    - [Installing on Local Windows](#installing-on-local-windows)
  - [AWS LocalStack](#aws-localstack)
    - [Installing on a Remote Linux Host](#installing-on-a-remote-linux-host-1)
  - [MailHog](#mailhog)
    - [Installing on Local Windows](#installing-on-local-windows-1)
  - [RocksDB](#rocksdb)
    - [Installing on a Remote Linux Host](#installing-on-a-remote-linux-host-2)
  - [Typesense](#typesense)
    - [Installing on a Remote Linux Host](#installing-on-a-remote-linux-host-3)
- [Useful Spring Boot Modules](#useful-spring-boot-modules)
  - [simi-java/simi-common/simi-common-req-res-log](#simi-javasimi-commonsimi-common-req-res-log)
  
# Introduction
**Simi Sandbox** is a developer-friendly toolkit for remote server management — enabling file transfer, command execution, and automated dependency setup.

# Core Scripts
## [scripts/cpfiles.sh](./scripts/cpfiles.sh)
[Back to Top](#table-of-contents)  
![](./docs/assets/scripts/cpfiles.svg)  
Automates uploading files from `ASSETS_ROOT` to mapped remote paths, according to 
rules in `PROPERTIES_FILE`.

Prerequisites:
  1. `sshpass` is installed locally.
  2. Make sure the current bash file has execution privileges: `chmod +x scripts/cpfiles.sh`
  3. Configure server variables in `scripts/AAA/config/server.sh`:
       - REMOTE_HOST
       - REMOTE_USER
       - REMOTE_SSH_PORT (default: 22)
       - REMOTE_PWD

Examples (run directly for easy start, using default settings):
  * `./scripts/cpfiles.sh`

      Copies `example1.txt` to the remote directory `~/examples`,
      and copies `example2.txt` and `example3.txt` from `scripts/AAA/assets/exampledir` 
      to the remote directory `~/examples/targetdir` on the test server.
  * `./scripts/cpfiles.sh ./scripts/AAA/assets/example-env.sh`

      Use the specified env configuration to copy `example2.txt` and `example3.txt` 
      from `scripts/AAA/assets/exampledir` to the remote directory
      `~/examples/targetdir2` on the test server.

Usage:
  * `./scripts/cpfiles.sh [<env.sh>]`

     You can define script options in a specified `env.sh` to override the default options in this script.

Script Options (variables in this script):
  * USE_RSYNC    : (true/false) Use `rsync` for uploading instead of `scp`.
  * USE_SUDO     : (true/false) If true, these commands will be executed with sudo privileges on the remote machine.
  * SILENT       : (true/false) If true, disables all overwrite confirmation prompts (auto-approve).
  * PROPERTIES_FILE   : Copies the folder contents or files corresponding to the keys in the properties file
      to the remote directories specified by the values.
  * ASSETS_ROOT       : The base directory where the relative paths (keys) from PROPERTIES_FILE are located.


Global Environment Variables:
  * ROOT : The absolute path of the scripts directory.

## [scripts/execr.sh](./scripts/execr.sh)
[Back to Top](#table-of-contents)  
![](./docs/assets/scripts/execr.svg)  
This script executes a local bash file on the remote server.

Prerequisites:
  1. `sshpass` is installed locally.
  2. Make sure the current bash file has execution privileges: `chmod +x scripts/execr.sh`
  3. Configure variables in `scripts/AAA/config/server.sh`:
       - REMOTE_HOST
       - REMOTE_USER
       - REMOTE_SSH_PORT (default: 22)
       - REMOTE_PWD

Examples (run directly for easy start, using default settings):
  * `./scripts/execr.sh ./scripts/AAA/assets/example-bash.sh`

     Execute the bash file `./scripts/AAA/assets/example-bash.sh` on your remote server.

Usage:
  * `./scripts/exec.sh <local-bash-file-path>`

    The first parameter `<local-bash-file-path>` is a local Bash file, which will be
    executed directly on the remote server.

Script Options (variables in this script):
  * USE_RSYNC    : (true/false) Use 'rsync' for uploading instead of 'scp'.
  * USE_SUDO     : (true/false) If true, the bash script will be executed with sudo privileges on the remote machine.

      In sudo mode, the script is first copied to the remote server before execution.  
      In non-sudo mode, it is executed directly on the remote server via SSH.
  * SILENT       : (true/false) If true, disables all confirmation prompts (auto-approve).
  * LOCAL_BASH_FILE       : Local bash file to execute
  * REMOTE_TMP_BASH_FILE  : The local bash script will be uploaded to this path on the remote server.
  * REMOTE_WORK_PATH      : The working directory on the remote server where the script will be executed.
                           
Global Env:
  * ROOT : The absolute path of scripts directory.

## [scripts/patchr.sh](./scripts/patchr.sh)
[Back to Top](#table-of-contents)  
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
  1. `sshpass` is installed locally.
  2. Make sure the current bash file has execution privileges: `chmod +x scripts/patchr.sh`
  3. Configure variables in `scripts/AAA/config/server.sh`:
       - REMOTE_HOST
       - REMOTE_USER
       - REMOTE_SSH_PORT (default: 22)
       - REMOTE_PWD
  4. [Optional] Create a file `~/examples/example-patch-remote.txt` on your remote server for testing purposes.

Examples (run directly for easy start, using default settings):
  * `./scripts/patchr.sh`

       Patch remote file `~/examples/example-patch-remote.txt` with the local file `scripts/AAA/assets/example-patch.txt`
  * `./scripts/patchr.sh recover`

       Recover from backup

Usage:
  * `./scripts/patchr.sh`

       Patch remote file
  * `./scripts/patchr.sh recover`

       Recover from backup

Script Options (variables inside this script):
  * LOCAL_FILE         : Path to the local file that will be uploaded.
  * REMOTE_UPLOAD_FILE : Remote file path where the local file will be uploaded.
  * REMOTE_FILE        : The original remote file to be backed up before overwriting.
  * REMOTE_BACKUP_FILE : Path where the backup of REMOTE_FILE will be stored.

  * USE_RSYNC          : (true/false) If true, use 'rsync' for uploading; otherwise use 'scp'.
  * SILENT             : (true/false) If true, suppresses all confirmation prompts (auto-approve).
  * USE_SUDO           : (true/false) If true, these commands will be executed with sudo privileges on the remote machine.

Global Env:
  * ROOT : The absolute path of scripts directory.

# Environment Configuration Helper
## Docker and Docker Compose
Docker is a platform that enables you to package, distribute, and run applications in lightweight, portable containers. It ensures consistency across different environments.
Docker Compose is a tool that helps define and manage multi-container Docker applications using a simple YAML file, allowing you to easily configure and run multiple services together.
### Installing on a Remote Linux Host
[Back to Top](#table-of-contents)  
Prerequisites:

   1. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD

Commands:

* `./scripts/execr.sh ./scripts/docker/install.sh`

    Run this command in the current project directory to install Docker and Docker Compose.

    Example Success Output:

       ...
       [INFO] Docker installed successfully: Docker version 28.3.2, build 578ccf6
       ...
       [INFO] Docker Compose installed successfully: Docker Compose version v2.38.2
       [INFO] Installation complete.
## Docker Desktop
Docker Desktop is an easy-to-install application that enables developers to build, share, and run containerized applications on Windows and Mac.

### Installing on Local Windows
[Back to Top](#table-of-contents)   
Docker Desktop is an easy-to-install application that enables developers to build, share, and run containerized applications on Windows and Mac.

Prerequisites:

  1. Open the Command Prompt with administrator privileges and navigate to the project root directory.

Commands:

* `call scripts\docker\install.bat`

    Install Docker Desktop locally on your Windows machine.
## AWS LocalStack
LocalStack is a fully functional local AWS cloud stack emulator.

### Installing on a Remote Linux Host
[Back to Top](#table-of-contents)  
Prerequisites:

   1. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD
   2. **Docker** and **Docker Compose** have been installed on the remote server. 
       (see [Docker and Docker Compose / Installing on a Remote Linux Host](#installing-on-a-remote-linux-host)).

Commands:

* `./scripts/cpfiles.sh ./scripts/aws/cpfiles-env.sh`

    Rely on cpfiles.sh to transfer `scripts/aws/assets/docker-compose.yml` to 
    `/opt/sandbox/aws` on the remote server.
* `./scripts/execr.sh ./scripts/aws/localstack-start.sh`

    Start LocalStack Service.
* `./scripts/execr.sh ./scripts/aws/localstack-stop.sh`

    Stop LocalStack Service.
## MailHog
MailHog is a lightweight, easy-to-use email testing tool that acts as a local SMTP server.

### Installing on Local Windows
[Back to Top](#table-of-contents)    
Prerequisites:

  1. **Docker Desktop** is installed and running locally. 
     (see [Docker Desktop / Installing on Local Windows](#installing-on-local-windows)).

Commands:

* `call scripts\mailhog\start.bat`

    Install and run the MailHog Docker image.
* `call scripts\mailhog\stop.bat`

    Stop the MailHog Docker image.

SMTP server: http://localhost:1025  
Web UI: http://localhost:8025

## RocksDB
RocksDB is a high-performance embedded key-value store developed by Facebook.   
It's optimized for fast storage, supports transactions, and is widely used in systems requiring low-latency data access.

### Installing on a Remote Linux Host
[Back to Top](#table-of-contents)  
Prerequisites:

   1. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD

Commands:

* `./scripts/execr.sh ./scripts/rocksdb/install.sh`

    Install RocksDB.
* `./scripts/execr.sh ./scripts/rocksdb/uninstall.sh`

    Uninstall script for RocksDB
## Typesense
Typesense is an open-source, fast, and easy-to-use search engine designed for building instant, typo-tolerant search experiences. It provides a simple API to index and search your data with minimal setup.


### Installing on a Remote Linux Host
[Back to Top](#table-of-contents)  
Prerequisites:

   1. Configure variables in `scripts/AAA/config/server.sh`:
        - REMOTE_HOST
        - REMOTE_USER
        - REMOTE_SSH_PORT (default: 22)
        - REMOTE_PWD

Commands:

* `./scripts/execr.sh ./scripts/typesense/install.sh`

    Install Typesense.
# Useful Spring Boot Modules
## simi-java/simi-common/simi-common-req-res-log
Checkout [RequestResponseLoggingFilter.java](./simi-java/simi-common/simi-common-req-res-log/src/main/java/com/simi/labs/common/reqres/log/RequestResponseLoggingFilter.java) for more details.

WebFlux filter for logging request and response information.  
Logs method, URI, safe headers, and truncated body for requests.  
Optionally logs status, safe headers, truncated body, and duration for responses
based on the 'logging.response.enabled' property.  
Handles GET requests, ensures response body is preserved, and logs response once.
Does not log client IP.

