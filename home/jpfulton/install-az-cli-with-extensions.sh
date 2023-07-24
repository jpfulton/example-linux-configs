#!/usr/bin/env bash

# exit on error
set -e;

## Install azure cli
curl -sL https://aka.ms/InstallAzureCLIDeb | bash;

# Log in
az login;

# Install ssh extension
az extension add --name ssh;
az extension show --name ssh;