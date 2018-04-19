echo "sourcing example env vars"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export SECURITYC_SERVER_CA_COMMON_NAME=bpanel
export SECURITYC_SERVER_CERT_COMMON_NAME=localhost
export SECURITYC_SERVER_CERT_IP=127.0.0.1
export SECURITYC_SERVER_CERT_DOMAIN=localhost
export SECURITYC_SERVER_CA_OUT=$DIR/ca.crt
export SECURITYC_SERVER_KEY_OUT=$DIR/server.key
export SECURITYC_SERVER_CERT_OUT=$DIR/server.crt
