#!/usr/bin/env bash

# expect at least two arguments
[ $# -lt 2 ] && exit 1;
 
# if the depth is non-zero , continue processing 
[ "$1" -ne 0 ] && exit 0;

IP=${untrusted_ip};
CERT_CN="$2"; # Passed in the form "CN=CommonName"
ALLOWED_CLIENTS_FILE="/etc/openvpn/allowed_clients";

sms-notify () {
  sudo sms-notify-cli vpn-bad-attempt -i "$1" -n "$2";
}

search-allowed-clients-file () {
  local PARSED_CN=${CERT_CN:3}; # Remove "CN=" from the string

  # Get a count of instances off the parsed CN on lines that don't start with "#"
  local CN_COUNT=$(cat ${ALLOWED_CLIENTS_FILE} | grep "^[^#;]" | grep -c ${PARSED_CN});

  if [ $CN_COUNT -lt 1 ]
    then
      return 1;
    else
      return 0;
  fi
}

search-allowed-clients-file;
if [ $? -eq 1 ]
  then
    sms-notify $IP $CERT_CN && exit 0;
fi

# catch all
exit 0;
