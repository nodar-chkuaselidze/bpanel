echo "sourcing example env vars"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export SECURITYC_SERVER_COMMON_NAME=localhost
export SECURITYC_SERVER_CERT_NAME=server.crt
export SECURITYC_SERVER_KEY_NAME=server.key
export SECURITYC_SERVER_KEY_OUTPUT_PATH=$DIR
export SECURITYC_SERVER_CERT_OUTPUT_PATH=$DIR
