#!/usr/bin/env bash

# expect at least two arguments
[ $# -lt 2 ] && exit 1;
 
# if the depth is non-zero , continue processing 
[ "$1" -ne 0 ] && exit 0;

IP=${untrusted_ip};
CERT_CN="$2"; # Passed in the form "CN=CommonName"
ALLOWED_CLIENTS_FILE="/etc/openvpn/allowed_clients";
DISALLOWED_UDP_PORTS="U:53,67-69,123,135,137-139,161-162,445,500,514,520,631,1434,1900,4500,49152";
DISALLOWED_TCP_PORTS="T:20,21-23,25,53,80,110-111,135,139,143,443,445,993,995,1723,3306,3389,5900,8080";

sms-notify-bad-attempt () {
  sudo sms-notify-cli vpn-bad-attempt -i "$1" -n "$2";
}

sms-notify-fw-test-fail () {
  sudo sms-notify-cli vpn-client-fw-test-fail -i "$1" -n "$2";
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

scan-client-open-ports () {
  local NMAP_RESULT=$(sudo nmap -Pn -sSU -T4 -p ${DISALLOWED_UDP_PORTS},${DISALLOWED_TCP_PORTS} $IP);
  local OPEN_COUNT=$(echo $NMAP_RESULTS | grep -v "open/filtered" | grep -c "open");

  if [ $OPEN_COUNT -eq 0 ]
    then
      return 0;
    else
      return 1;
  fi
}

search-allowed-clients-file;
if [ $? -eq 1 ]
  then
    sms-notify-bad-attempt $IP $CERT_CN && exit 1; # Notify and disallow the connection
fi

scan-client-open-ports;
if [ $? -eq 1 ]
  then
    sms-notify-fw-test-fail $IP $CERT_CN && exit 1; # Notify and disallow the connection
fi

# catch all
exit 0;
