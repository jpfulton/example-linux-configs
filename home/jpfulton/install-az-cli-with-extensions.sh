#!/usr/bin/env bash

# exit on error
set -e;

# ensure this script is running as root or sudo
if [ $(id -u) -ne 0 ]
  then
    echo "This script must be run as root or in a sudo context. Exiting.";
    exit 1;
fi

## Install azure cli: REVIEW MS SCRIPT PRIOR TO EXECUTION
curl -sL https://aka.ms/InstallAzureCLIDeb | bash;

# Log in
az login;

# Install ssh extension
az extension add --name ssh;
az extension show --name ssh;