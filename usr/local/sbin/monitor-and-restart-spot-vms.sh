#!/usr/bin/env bash

# exit on error
set -e;

RESOURCE_GROUP="personal-network"

echo "Querying for deallocated VMs...";
SPOT_ALLOCATION_QUERY="
	[?
		billingProfile.maxPrice != null && 
		powerState == 'VM deallocated'
	].{Name:name}";
	
DEALLOCATED_VM_NAMES=$(az vm list -g ${RESOURCE_GROUP} -d -o tsv --query "${SPOT_ALLOCATION_QUERY}");

VM_NAMES_ARRAY=($DEALLOCATED_VM_NAMES);
ARRAY_LENGTH=${#VM_NAMES_ARRAY[@]};

if [ $ARRAY_LENGTH -ge 1 ]
	then
		echo "Found ${ARRAY_LENGTH} deallocated VM(s).";

		for (( i=0; i<$ARRAY_LENGTH; i++ )); 
		do
			echo "Attempting to start VM: ${VM_NAMES_ARRAY[i]}";
			az vm start -g ${RESOURCE_GROUP} --name ${VM_NAMES_ARRAY[i]};
		done

	else
		echo "No deallocated VMs discovered.";
fi
