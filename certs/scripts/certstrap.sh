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
  echo "-ip - ip on X509v3 Subject Alternative Name, can be multiple values comma separated"
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
    log "creating CA"
    certstrap init --common-name "$ca_common_name" --passphrase ""
else
    log "CA already found"
fi
# creates the files:
# "out/$ca_common_name.key"
# "out/$ca_common_name.crt"
# "out/$ca_common_name.crl"

request_cert_arg=""
[[ ! -z "$cert_common_name" ]] && request_cert_arg="${request_cert_arg} --common-name ${cert_common_name}"
[[ ! -z "$ip" ]] && request_cert_arg="${request_cert_arg} --ip ${ip}"
[[ ! -z "$domain" ]] && request_cert_arg="${request_cert_arg} --domain ${domain}"

log "Invoking certstrap with args: ${request_cert_arg} --passphrase \"\""
certstrap request-cert $request_cert_arg --passphrase ""

# creates the files:
# "out/$cert_common_name.key"
# "out/$cert_common_name.csr"

# TODO: determine if edge cases around autoformatting of camelcase vs snakecase
certstrap sign "${cert_common_name}" --CA "${ca_common_name}"

# creates the files:
# "out/$cert_common_name.crt"

# now we want:
# "out/$cert_common_name.crt"
# "out/$cert_common_name.key"
# in the proper location

ca_file="$DIR/out/$ca_common_name.crt"
cert_file="$DIR/out/$cert_common_name.crt"
key_file="$DIR/out/$cert_common_name.key"

move "$ca_file" "$ca_path_out"
move "$cert_file" "$cert_path_out"
move "$key_file" "$key_path_out"

# remove out directory
rm -rf "$DIR/out"
