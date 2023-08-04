#!/usr/bin/env bash

ENDPOINT_IP="169.254.169.254";
API_VERSION="2020-07-01";

HEADER="Metadata:true";
ENDPOINT_URL="http://${ENDPOINT_IP}/metadata/scheduledevents?api-version=${API_VERSION}";

if [ "$(curl -s -H ${HEADER} ${ENDPOINT_URL} | grep -c Preempt)" -ge 1 ]
    then
        echo "Azure preempt event found... Shutting down.";
        wall "Azure preempt event found... Shutting down cleanly prior to eviction.";
        sms-notify-cli eviction $(hostname);

        sleep 5;
	    shutdown now "Shutting down. Virtual machine is being evicted.";
    else
        echo "No Azure preempt event found.";
fi
