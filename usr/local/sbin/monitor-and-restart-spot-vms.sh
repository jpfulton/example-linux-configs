#!/usr/bin/env bash

# exit on error
set -e;

RESOURCE_GROUP="personal-network"

DEALLOCATED_NAMES=$(az vm list -g ${RESOURCE_GROUP} -d -o tsv --query "[?billingProfile.maxPrice != null && powerState == 'VM deallocated'].{Name:name}");

NAMES_ARRAY=($DEALLOCATED_NAMES);
ARRAY_LENGTH=${#NAMES_ARRAY[@]};

if [ $ARRAY_LENGTH -ge 1 ]
    then
	echo "Found ${ARRAY_LENGTH} deallocated VM(s).";

	for (( i=0; i<$ARRAY_LENGTH; i++ )); 
	do
	    echo "Attempting to start VM: ${NAMES_ARRAY[i]}";
	    az vm start -g ${RESOURCE_GROUP} --name ${NAMES_ARRAY[i]};
        done
fi
