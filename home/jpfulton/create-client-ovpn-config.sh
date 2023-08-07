#!/usr/bin/env bash

# ensure this script is running as root or sudo
if [ $(id -u) -ne 0 ]
  then
    echo "This script must be run as root or in a sudo context. Exiting.";
    exit 1;
fi

# ensure this script has two arguments or prompt user for inputs
if [ "$#" -ne 2 ]
  then
    echo "INFO: This script may be run with two positional arguments: <CN> and <remoteDNS>.";
    echo
    echo "Manually collecting inputs...";
    echo -n "Enter a client certificate common name: ";
    read CLIENT_CERT_CN;
    echo -n "Enter remote server DNS: ";
    read REMOTE_DNS;
  else
    CLIENT_CERT_CN="$1";
    REMOTE_DNS="$2";
fi

if [ "$CLIENT_CERT_CN" == "" ]
  then
    echo "ERROR: No client certificate common name provided.";
    exit 1;
fi

if [ "$REMOTE_DNS" == "" ]
  then
    echo "ERROR: No remote server DNS name provided.";
    exit 1;
fi

OPENVPN_DIR="/etc/openvpn/";
BASE_CONFIG="${OPENVPN_DIR}/base-client-config.ovpn";
EASY_RSA_DIR="${OPENVPN_DIR}/easy-rsa/";
EASY_RSA_BIN="${EASY_RSA_DIR}/easyrsa";

KEY_DIR="${EASY_RSA_DIR}/pki/private/";
CERT_DIR="${EASY_RSA_DIR}/pki/issued/";

generate-client-certificate () {
  if [ ! -f ${CERT_DIR}/${CLIENT_CERT_CN}.crt ]
  then
    echo "INFO: Generating client keys...";
    echo "INFO: You will be prompted for the CA passphrase if the CA was encrypted.";

    CURRENT_PWD=$(pwd); # Save current working directory to run later
    cd ${EASY_RSA_DIR};

    $EASY_RSA_BIN build-client-full ${CLIENT_CERT_CN} nopass;
    if [ $? -ne 0 ]
    then
      echo "ERROR: Error running easyrsa. Exiting.";
      exit 1;
    fi

    cd ${CURRENT_PWD}; # Return to old working directory
  else
    echo "WARN: Client key of the same name has been found. Using that key...";
  fi
}

generate-client-configuration-file () {
  if [ ! -f ${OPENVPN_DIR}/ca.crt ]; then
    echo "ERROR: CA certificate not found";
    exit 1;
  fi

  if [ ! -f ${CERT_DIR}/${CLIENT_CERT_CN}.crt ]; then
    echo "ERROR: User certificate not found";
    exit 1;
  fi

  if [ ! -f ${KEY_DIR}/${CLIENT_CERT_CN}.key ]; then
    echo "ERROR: User private key not found";
    exit 1;
  fi

  if [ ! -f ${OPENVPN_DIR}/ta.key ]; then
    echo "ERROR: TLS Auth key not found";
    exit 1;
  fi

  echo "INFO: Generating client configuration file...";

  cat ${BASE_CONFIG} \
    <(echo "remote ${REMOTE_DNS} 1194") \
    <(echo "<ca>") \
    ${OPENVPN_DIR}/ca.crt \
    <(echo "</ca>") \
    <(echo "<cert>") \
    ${CERT_DIR}/${CLIENT_CERT_CN}.crt \
    <(echo "</cert>") \
    <(echo "<key>") \
    ${KEY_DIR}/${CLIENT_CERT_CN}.key \
    <(echo "</key>") \
    <(echo "<tls-auth>") \
    ${OPENVPN_DIR}/ta.key \
    <(echo "</tls-auth>") \
    > ${CLIENT_CERT_CN}.ovpn

  chmod o-r ${CLIENT_CERT_CN}.ovpn;

  echo "INFO: Client configuration created in $(pwd)/${CLIENT_CERT_CN}.ovpn";
  echo "WARN: Transmit and store this configuration securely.";
  echo "WARN: It contains a private key and a pre-shared secret.";
}

main () {
  generate-client-certificate;
  generate-client-configuration-file;

  echo "---";
  echo;

  exit 0;
}

main;
