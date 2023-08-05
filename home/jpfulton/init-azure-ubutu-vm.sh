#!/usr/bin/env bash

# ensure this script is running as root or sudo
if [ $(id -u) -ne 0 ]
  then
    echo "This script must be run as root or in a sudo context. Exiting.";
    exit 1;
fi

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";

# Upgrade base image packages
echo "Upgrading base packages...";
apt update;
apt upgrade -y;
echo "---";
echo;

# Set up local firewall basics
DEFAULTS_PATH="/etc/default/";
UFW_DEFAULTS_FILE="ufw";
if [ $(ufw status | grep -c inactive) -ge 1 ]
  then
    echo "Local firewall is inactive. Configuring and enabling with SSH rule...";

    wget ${BASE_REPO_URL}${DEFAULTS_PATH}${UFW_DEFAULTS_FILE} -O ${UFW_DEFAULTS_FILE};
    mv ${UFW_DEFAULTS_FILE} ${DEFAULTS_PATH};

    ufw allow ssh;
    ufw show added;
    ufw enable;
    ufw status numbered;
  
  else
    echo "Local fireall is active. No configuration or rules applied.";
fi
echo "---";
echo;

# Set up custom MOTD script
MOTD_PATH="/etc/update-motd.d/";
MOTD_FILE="01-custom";
if [ ! -f ${MOTD_PATH}${MOTD_FILE} ]
  then
    echo "Setting up custom MOTD script...";

    apt install -y neofetch inxi;
    wget ${BASE_REPO_URL}${MOTD_PATH}${MOTD_FILE} -O ${MOTD_FILE};
    chmod a+x ./${MOTD_FILE};
    mv ./${MOTD_FILE} ${MOTD_PATH}${MOTD_FILE};

    echo "---";
    echo;
fi

# Install Node as needed
which node >> /dev/null;
if [ $? -eq 0 ]
  then
    NODE_VERSION=$(node --version);
    if [ $NODE_VERSION == "v12.22.9" ]
      then
        echo "Default node package detected. Removing.";
        apt remove nodejs;
        apt autoremove;
      else
        echo "Detected alternate version of node: ${NODE_VERSION}";
        echo "Ensure that version is above v18.0.0 or manually use nvm.";
    fi
  else
    echo "Node not detected. Preparing installation of node v18.x.";

    curl -sL  https://deb.nodesource.com/setup_18.x | bash -;
    apt install -y nodejs;
fi

# Install Yarn as needed
which yarn >> /dev/null;
if [ $? -eq 1 ]
  then
    echo "Yarn not detected. Preparing to install.";

    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null;
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list;
    apt update;
    apt install -y yarn;
  else
    YARN_VERSION=$(yarn --version);
    echo "Found yarn version: ${YARN_VERSION}";
fi

# Install or upgrade sms-notify-cli utility
which sms-notify-cli >> /dev/null;
if [ $? -eq 1 ]
  then
    echo "sms-notify-cli utility not detected. Preparing to install.";
    yarn global add @jpfulton/net-sms-notifier-cli;
  else
    echo "Found sms-notify-cli utility. Attempting update.";
    yarn global upgrade @jpfulton/net-sms-notifier-cli@latest;
fi

# Initialize sms-notify-cli configuration
NOTIFIER_CONFIG="/etc/sms-notifier/notifier.json";
if [ -f $NOTIFIER_CONFIG ]
  then
    echo "Found notifier configuration. Validating with current version.";

    sms-notify-cli validate;
    if [ $? -eq 0 ]
      then
        echo "Configuration file validation passes on current version.";
      else
        echo "Invalid configuration file. Manually correct.";
    fi
  else
    echo "No notifier configuration found. Initializing...";
    echo "Manual configuration to the ${NOTIFIER_CONFIG} file will be required.";
    sms-notify-cli init;
fi

# Set up eviction query and shutdown script
EVICTION_QUERY_CRON_SNIPPET_FILE="preempt-query";
EVICTION_QUERY_SCRIPT="query-for-preempt-event.sh";
echo "Setting up eviction query script...";

wget ${BASE_REPO_URL}/usr/local/sbin/${EVICTION_QUERY_SCRIPT};
chmod ug+x ./${EVICTION_QUERY_SCRIPT}
mv ./${EVICTION_QUERY_SCRIPT} /usr/local/sbin/

wget ${BASE_REPO_URL}/etc/cron.d/${EVICTION_QUERY_CRON_SNIPPET_FILE};
mv ./${EVICTION_QUERY_CRON_SNIPPET_FILE} /etc/cron.d/

echo "---";
echo;
