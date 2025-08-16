#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/AAA/config/global.sh"

# ================================================================== Required Configurations
# Import global environment variables
echo "------------------------------------------------- cpfiles - Test Case 1"
# bash ./scripts/cpfiles.sh
echo "------------------------------------------------- cpfiles - Test Case 2"
# bash ./scripts/cpfiles.sh ./scripts/AAA/assets/example-env.sh
echo "------------------------------------------------- cpfiles - Test Case 3"
bash ./scripts/cpfiles.sh ./scripts/AAA/assets/example-env-sudo.sh
