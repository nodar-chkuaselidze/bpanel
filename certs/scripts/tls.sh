#!/bin/bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# set default values
cert_name=cert.crt
key_name=cert.key
cert_out="$DIR/$cert_name"
key_out="$DIR/$key_name"
verbose=false

# TODO: use dev config for now
config_path=/etc/opt/securityc/openssl-dev.conf
alt_name=localhost

# the wrapper script checks to make sure that
# empty strings are not passed in as arguments
while [[ "$#" -gt 0 ]]; do case $1 in
  -an|--alt-name) alt_name="$2"; shift;;
  -co|--cert-out) cert_out="$2"; shift;;
  -ko|--key-out) key_out="$2"; shift;;
  -c|--config) config_path="$2"; shift;;
  -v|--verbose) verbose=true;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

if [ $verbose = true ]; then
    echo
    echo "variables used:"
    echo
    echo "cert output: ${cert_out}"
    echo "key output: ${key_out}"
    echo
fi

# export variables needed to build the config
export docker_dns="$alt_name"

# set vars variable, a : separated string
# of variables to be replaced in the input file
VARS='${docker_dns}'
config=$(envsubst "$VARS" < "${config_path}")

if [ $verbose = true ]; then
    echo
    echo "configuration used:"
    echo
    printf "%s" "$config"
    echo
	echo
fi

openssl req -x509 -out "${cert_out}" \
    -keyout "${key_out}" \
    -newkey rsa:2048 -days 3650 \
    -nodes -sha256 \
    -subj "/C=US/ST=California/L=SF/O=purse.io/OU=bcoin/CN=securityc bpanel" \
    -extensions v3_req \
    -config <( printf "%s" "$config" )
# TODO: test if printf is needed here

