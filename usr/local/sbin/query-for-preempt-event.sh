#!/usr/bin/env bash

ENDPOINT_IP="169.254.169.254";
API_VERSION="2020-07-01";
LOG_FILE="/var/log/azure-eviction.log";

# ensure this script is running as root or sudo
if [ $(id -u) -ne 0 ]
  then
    echo "This script must be run as root or in a sudo context. Exiting.";
    exit 1;
fi

CONFIG_DIR="/etc/azure";
LOCK_FILE="${CONFIG_DIR}/eviction-monitor.lock";
if [ ! -d $CONFIG_DIR ]
	then
		echo "Configuration directory does not exist. Creating...";
		mkdir $CONFIG_DIR;
fi

# This script can be long running. Use a lock file.
if [ -f $LOCK_FILE ]
	then
		echo "Found lock file.";
		RUNNING_PID=$(cat $LOCK_FILE);
		if [ ! -n "$(ps -p $RUNNING_PID -o pid=)" ]
			then
				echo "Lock file is stale. Removing and continuing...";
				rm $LOCK_FILE;
			else
				echo "Another instance of this script is running at PID: ${RUNNING_PID}. Exiting...";
				exit 0;
		fi
	else
		touch $LOCK_FILE;
		echo $BASHPID > $LOCK_FILE;
fi

HEADER="Metadata:true";
ENDPOINT_URL="http://${ENDPOINT_IP}/metadata/scheduledevents?api-version=${API_VERSION}";

if [ "$(curl -s -H ${HEADER} ${ENDPOINT_URL} | grep -c Preempt)" -ge 1 ]
    then
        echo "Azure preempt event found... Shutting down.";
        wall "Azure preempt event found... Shutting down cleanly prior to eviction.";

        echo "$(date) - EVICTION - Azure preempt event discovered." >> $LOG_FILE;
        sms-notify-cli eviction $(hostname);

        sleep 5;
	    shutdown now "Shutting down. Virtual machine is being evicted.";

        # Sleep until the shutdown completes. This may leave a stale lock file
        # behind, it will be cleaned up based on PID in next run.
        sleep 30;
    else
        echo "No Azure preempt event found.";
fi

# Remove lock file.
rm $LOCK_FILE;
