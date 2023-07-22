#!/usr/bin/env bash

echo "Checking for current Azure User:";
az ad signed-in-user show;
if [ $? -ne 0 ]
  then
    echo "Azure Login required... Run 'az login'.";
    exit 1;
fi

echo;
echo "Refreshing SSH certificates...";
az ssh config --ip \* --file ~/.ssh/az_config --overwrite;

echo;
echo "---";
echo "Done.";
