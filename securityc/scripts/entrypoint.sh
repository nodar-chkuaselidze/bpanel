#!/bin/bash

echo "securityc start"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

verbose=
while [[ "$#" -gt 0 ]]; do case $1 in
  -v|--verbose) verbose='-v';;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

echo "starting cert generation"

$DIR/securityc.sh $verbose

echo "starting nginx"
# TODO(mark): envsubst nginx config

exec nginx -g 'daemon off;'

