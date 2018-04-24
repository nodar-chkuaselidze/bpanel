echo "sourcing example env vars"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# CA creation arguments
export SECURITYC_SERVER_CA_COMMON_NAME=bpanel
export SECURITYC_SERVER_CERT_COMMON_NAME=localhost
export SECURITYC_SERVER_CERT_IP=127.0.0.1
export SECURITYC_SERVER_CERT_DOMAIN=localhost

export SECURITYC_SERVER_CA_OUT=$DIR/ca.crt
export SECURITYC_SERVER_CA_IN=$DIR/ca.crt

export SECURITYC_SERVER_CA_KEY_IN=$DIR/ca.key
export SECURITYC_SERVER_CA_KEY_OUT=$DIR/ca.key

export SECURITYC_SERVER_KEY_OUT=$DIR/server.key
export SECURITYC_SERVER_CERT_OUT=$DIR/server.crt
