#!/usr/bin/env bash

[ $# -lt 2 ] && exit 1;
 
# if the depth is non-zero , continue processing 
[ "$1" -ne 0 ] && exit 0;

sudo sms-notify-cli vpn-attempt -i ${untrusted_ip} -n "$2";
exit 0;