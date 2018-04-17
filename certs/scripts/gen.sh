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
while [[ "$#" > 0 ]]; do case $1 in
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
CONFIG_FILE="openssl-slim.conf"

# export variables needed to build the config
export common_name

# set vars variable
# : separated string of variables to be replaced in the input file
VARS='${common_name}'
config=$(envsubst "$VARS" < "${CONFIG_DIR}/${CONFIG_FILE}")

# TODO: comment out old way for now
# config="[dn]\nCN=${common_name}\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:${common_name}\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth"

# TODO: comment out second old way for now
# config="[dn]\nCN=${common_name}\n"
# config="${config}[req]\ndistinguished_name = dn\n"
# config="${config}[EXT]\nsubjectAltName=DNS:${common_name}\n"
# config="${config}keyUsage=digitalSignature\n"
# config="${config}extendedKeyUsage=serverAuth"

if [ $verbose = true ]; then
    echo
    echo "configuration used:"
    echo
    printf "$config"
    echo
	echo
fi

# TODO: debug shortcircuit
# echo "short circuit, exiting..."
# exit 0

openssl req -x509 -out "${cert_output_dir}/${cert_name}" \
    -keyout "${key_output_dir}/${key_name}" \
    -newkey rsa:2048 \
    -nodes -sha256 \
    -subj "/CN=${common_name}" \
    -extensions EXT \
    -config <( printf "$config" )

