#!/usr/bin/env bash

# expect at least two arguments
[ $# -lt 2 ] && exit 1;
 
# if the depth is non-zero , continue processing 
[ "$1" -ne 0 ] && exit 0;

IP=${untrusted_ip};
CERT_CN="$2"; # Passed in the form "CN=CommonName"
STATUS_FILE="/var/log/openvpn/openvpn-status.log";

sms-notify () {
  sudo sms-notify-cli vpn-attempt -i "$1" -n "$2";
}

search-status-file () {
  local PARSED_CN=${CERT_CN:3}; # Remove "CN=" from the string
  local CN_COUNT=$(cat ${STATUS_FILE} | grep -c ${PARSED_CN});

  if [ $CN_COUNT -lt 2 ]
    then
      return 1;
    else
      return 0;
  fi
}

search-status-file;
if [ $? -eq 1 ]
  then
    sms-notify $IP $CERT_CN && exit 0;
fi

# catch all
exit 0;
