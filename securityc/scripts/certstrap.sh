#!/bin/bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ca_common_name=""
cert_common_name=""
ip=""
domain=""
verbose=false

ca_path_out="$DIR/ca.crt"
cert_path_out="$DIR/cert.crt"
key_path_out="$DIR/key.crt"

function log() {
    if [ $verbose == true ]; then
        echo
        echo "$1"
        echo
    fi
}

function usage() {
  echo "generate a ca cert, a csr, then sign"
  echo "-c|--ca-common-name - common name on generated ca cert"
  echo "-ce|--cert-common-name - common name on generated cert"
  echo "-ip|--ip - ip on X509v3 Subject Alternative Name, can be multiple values comma separated"
  echo "-d|--domain - dns on X509v3 Subject Alternative Name, can be multiple values comman separated"
  echo "-ao|--ca-path-out - path to generated ca"
  echo "-co|--cert-path-out - path to generated cert"
  echo "-ko|--key-path-out - path to generated key"
  echo "-v|--verbose"
}

function move() {
  log "making $1 writable"
  chmod u+w "$1"
  log "Runing command:"
  log "mv $1 $2"
  mv -f "$1" "$2"
  log "removing write permissions $2"
  chmod u-w "$2"
}

while [[ "$#" -gt 0 ]]; do case $1 in
  -c|--ca-common-name) ca_common_name="$2"; shift;;
  -ce|--cert-common-name) cert_common_name="$2"; shift;;
  -ip|--ip) ip="$2"; shift;;
  -d|--domain) domain="$2"; shift;;
  -ao|--ca-out) ca_path_out="$2"; shift;;
  -co|--cert-out) cert_path_out="$2"; shift;;
  -ko|--key-out) key_path_out="$2"; shift;;
  -v|--verbose) verbose=true;;
  *) echo "Unknown parameter passed: $1"; usage; exit 1;;
esac; shift; done


log "CA Common Name: $ca_common_name"

# create new ca if one doesn't exist already
if [[ ! -f "$PWD/out/$ca_common_name.key" ]]; then
    # create the files:
    # "$PWD/out/$ca_common_name.key"
    # "$PWD/out/$ca_common_name.crt"
    # "$PWD/out/$ca_common_name.crl"
    log "Invoking certstrap init with args: --common-name $ca_common_name --passphrase \"\""
    certstrap init --common-name "$ca_common_name" --passphrase ""
else
    log "CA already found"
fi

request_cert_arg=""
[[ ! -z "$cert_common_name" ]] && request_cert_arg="${request_cert_arg} --common-name ${cert_common_name}"
[[ ! -z "$ip" ]] && request_cert_arg="${request_cert_arg} --ip ${ip}"
[[ ! -z "$domain" ]] && request_cert_arg="${request_cert_arg} --domain ${domain}"

log "Invoking certstrap request-cert with args: ${request_cert_arg} --passphrase \"\""
log "Running from directory: $PWD"

# create the files:
# "$PWD/out/$cert_common_name.key"
# "$PWD/out/$cert_common_name.csr"
certstrap request-cert $request_cert_arg --passphrase ""

# creates the files:
# "$PWD/out/$cert_common_name.crt"
# TODO (mark): determine if edge cases around autoformatting of camelcase vs snakecase
certstrap sign "${cert_common_name}" --CA "${ca_common_name}"


# move these files to the proper location
# "$PWD/out/$cert_common_name.crt"
# "$PWD/out/$cert_common_name.key"
OUT_DIR=
# handle case when in root to prevent double /
if [ "$PWD" == "/" ]; then
    OUT_DIR="/out"
else
    OUT_DIR="${PWD}/out"
fi

ca_file="$OUT_DIR/$ca_common_name.crt"
cert_file="$OUT_DIR/$cert_common_name.crt"
key_file="$OUT_DIR/$cert_common_name.key"

# move the ca_file to a place
# where the user can access it
move "$ca_file" "$ca_path_out"

move "$cert_file" "$cert_path_out"
move "$key_file" "$key_path_out"


# remove out directory
rm -rf "$OUT_DIR"

