#!/usr/bin/env bash

SUBSCRIPTION_ID="";
RESOURCE_GROUP="";
SP_NAME="";

az ad sp create-for-rbac 
  --name $SP_NAME \
	--role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --create-cert;
