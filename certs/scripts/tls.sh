#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# set default values
common_name=localhost
cert_name=cert.crt
key_name=cert.key
cert_output_dir=$PWD
key_output_dir=$PWD
verbose=false

# the wrapper script checks to make sure that
# empty strings are not passed in as arguments
while [[ "$#" -gt 0 ]]; do case $1 in
  -cn|--common-name) common_name="$2"; shift;;
  -c|--cert-name) cert_name="$2"; shift;;
  -k|--key-name) key_name="$2"; shift;;
  -oc|--cert-output-dir) cert_output_dir="$2"; shift;;
  -ok|--key-output-dir) key_output_dir="$2"; shift;;
  -v|--verbose) verbose=true;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# TODO: use distinguished_name
distinguished_name=purse

if [ $verbose = true ]; then
    echo
    echo "variables used:"
    echo
    echo "common name: ${common_name}"
    echo "cert name: ${cert_name}"
    echo "key name: ${key_name}"
    echo "cert output dir: ${cert_output_dir}"
    echo "key output dir: ${key_output_dir}"
    echo "distinguished_name: ${distinguished_name}"
    echo
fi

# TODO: use envsubst + a true config file for openssl
# hardcode ssl config for now
BASE_DIR="${DIR}/.."
CONFIG_DIR="${BASE_DIR}/config"
CONFIG_FILE="openssl-dev.conf"

# export variables needed to build the config
export docker_dns=bcoin

# set vars variable, a : separated string
# of variables to be replaced in the input file
VARS='${docker_dns}'
config=$(envsubst "$VARS" < "${CONFIG_DIR}/${CONFIG_FILE}")


if [ $verbose = true ]; then
    echo
    echo "configuration used:"
    echo
    printf "%s" "$config"
    echo
	echo
fi

openssl req -x509 -out "${cert_output_dir}/${cert_name}" \
    -keyout "${key_output_dir}/${key_name}" \
    -newkey rsa:2048 -days 3650 \
    -nodes -sha256 \
    -subj "/C=US/ST=California/L=SF/O=purse.io/OU=bcoin/CN=securityc bpanel" \
    -extensions v3_req \
    -config <( printf "%s" "$config" )

