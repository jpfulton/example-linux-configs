#!/usr/bin/env bash

ENDPOINT_IP="169.254.169.254";
API_VERSION="2020-07-01";

HEADER="Metadata:true";
ENDPOINT_URL="http://${ENDPOINT_IP}/metadata/scheduledevents?api-version=${API_VERSION}";

if [ "$(curl -s -H ${HEADER} ${ENDPOINT_URL} | grep -c Preempt)" -ge 1 ]
    then
        echo "Preempt event found...";
	    shutdown now "Shutting down. Virutal machine is being evicted.";
fi
