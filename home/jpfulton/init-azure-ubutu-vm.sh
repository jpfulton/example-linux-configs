#!/usr/bin/env bash

# ensure this script is running as root or sudo
if [ $(id -u) -ne 0 ]
  then
    echo "This script must be run as root or in a sudo context. Exiting.";
    exit 1;
fi

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";
HOME_DIR="/home/jpfulton/";

upgrade-base-packages () {
  # Upgrade base image packages
  echo "Upgrading base packages...";
  apt update;
  apt upgrade -y;
  echo "---";
  echo;
}

setup-firewall-defaults-and-ssh () {
  # Set up local firewall basics
  local DEFAULTS_PATH="/etc/default/";
  local UFW_DEFAULTS_FILE="ufw";
  if [ $(ufw status | grep -c inactive) -ge 1 ]
    then
      echo "Local firewall is inactive. Configuring and enabling with SSH rule...";

      wget -q ${BASE_REPO_URL}${DEFAULTS_PATH}${UFW_DEFAULTS_FILE} -O ${UFW_DEFAULTS_FILE};
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
}

setup-motd () {
  # Set up custom MOTD script
  local MOTD_PATH="/etc/update-motd.d/";
  local MOTD_FILE="01-custom";
  if [ ! -f ${MOTD_PATH}${MOTD_FILE} ]
    then
      echo "Setting up custom MOTD script...";

      apt install -y neofetch inxi;
      wget -q ${BASE_REPO_URL}${MOTD_PATH}${MOTD_FILE} -O ${MOTD_FILE};
      chmod a+x ./${MOTD_FILE};
      mv ./${MOTD_FILE} ${MOTD_PATH}${MOTD_FILE};

      echo "---";
      echo;
  fi
}

setup-nodejs () {
  # Install Node as needed
  which node >> /dev/null;
  if [ $? -eq 0 ]
    then
      local NODE_VERSION=$(node --version);
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

  echo "---";
  echo;
}

setup-yarn () {
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
      local YARN_VERSION=$(yarn --version);
      echo "Found yarn version: ${YARN_VERSION}";
  fi

  echo "---";
  echo;
}

setup-sms-notifier () {
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
  local NOTIFIER_CONFIG="/etc/sms-notifier/notifier.json";
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

  echo "---";
  echo;
}

setup-eviction-shutdown-system () {
  # Set up eviction query and shutdown script
  local EVICTION_QUERY_CRON_SNIPPET_FILE="preempt-query";
  local EVICTION_QUERY_SCRIPT="query-for-preempt-event.sh";
  echo "Setting up eviction query script...";

  wget -q ${BASE_REPO_URL}/usr/local/sbin/${EVICTION_QUERY_SCRIPT};
  chmod ug+x ./${EVICTION_QUERY_SCRIPT}
  mv ./${EVICTION_QUERY_SCRIPT} /usr/local/sbin/

  wget -q ${BASE_REPO_URL}/etc/cron.d/${EVICTION_QUERY_CRON_SNIPPET_FILE};
  mv ./${EVICTION_QUERY_CRON_SNIPPET_FILE} /etc/cron.d/

  echo "---";
  echo;
}

setup-nmap () {
  # Install nmap as needed
  which nmap >> /dev/null;
  if [ $? -eq 1 ]
    then
      echo "nmap not detected. Preparing to install.";
      apt install -y nmap;

      echo "---";
      echo;
  fi
}

setup-openvpn-support-scripts () {
  # Set up OpenVPN scripts if OpenVPN is installed
  local OPENVPN_DIR="/etc/openvpn/";
  local BASE_CLIENT_CONFIG="base-client-config.ovpn";
  local CLIENT_CONFIG_SCRIPT="create-client-ovpn-config.sh";
  local OPENVPN_SCRIPTS_DIR="/etc/openvpn/scripts/";
  local CONNECT_SCRIPT="on-connect.sh";
  local DISCONNECT_SCRIPT="on-disconnect.sh";
  local VERIFY_SCRIPT="on-tls-verify.sh";
  if [ -d $OPENVPN_DIR ]
    then
      echo "OpenVPN configuration folder exists.";

      setup-nmap;

      echo "Installing OpenVPN client template...";
      wget -q ${BASE_REPO_URL}${OPENVPN_DIR}${BASE_CLIENT_CONFIG};
      mv ./${BASE_CLIENT_CONFIG} ${OPENVPN_DIR}${BASE_CLIENT_CONFIG};

      echo "Installing OpenVPN client config generation script...";
      wget -q ${BASE_REPO_URL}${HOME_DIR}${CLIENT_CONFIG_SCRIPT};
      chmod a+x ./${CLIENT_CONFIG_SCRIPT};

      echo "Installing OpenVPN scripts...";
      if [ ! -d $OPENVPN_SCRIPTS_DIR ]
        then
          echo "Creating scripts directory.";
          mkdir $OPENVPN_SCRIPTS_DIR;
      fi

      wget -q ${BASE_REPO_URL}${OPENVPN_SCRIPTS_DIR}${CONNECT_SCRIPT};
      chmod a+x ./${CONNECT_SCRIPT};
      mv ./${CONNECT_SCRIPT} ${OPENVPN_SCRIPTS_DIR}${CONNECT_SCRIPT};

      wget -q ${BASE_REPO_URL}${OPENVPN_SCRIPTS_DIR}${DISCONNECT_SCRIPT};
      chmod a+x ./${DISCONNECT_SCRIPT};
      mv ./${DISCONNECT_SCRIPT} ${OPENVPN_SCRIPTS_DIR}${DISCONNECT_SCRIPT};

      wget -q ${BASE_REPO_URL}${OPENVPN_SCRIPTS_DIR}${VERIFY_SCRIPT};
      chmod a+x ./${VERIFY_SCRIPT};
      mv ./${VERIFY_SCRIPT} ${OPENVPN_SCRIPTS_DIR}${VERIFY_SCRIPT};

      echo "---";
      echo;
  fi
}

main () {
  upgrade-base-packages;
  setup-firewall-defaults-and-ssh;
  setup-motd;
  setup-nodejs;
  setup-yarn;
  setup-sms-notifier;
  setup-eviction-shutdown-system;
  setup-openvpn-support-scripts;

  echo "---";
  echo "Done.";
  echo;
}

main;