#!/usr/bin/env bash

# exit on error
set -e;

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";

# Upgrade base image packages
echo "Upgrading base packages...";
apt update;
apt upgrade -y;
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
