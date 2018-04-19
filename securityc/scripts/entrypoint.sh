#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "entrypoint securityc"

$DIR/securityc.sh -v

echo "starting nginx"
# TODO(mark): envsubst nginx config

exec nginx -g 'daemon off;'
