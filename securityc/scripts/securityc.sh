#!/bin/bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

verbose=false
while [[ "$#" -gt 0 ]]; do case $1 in
  -v|--verbose) verbose=true;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# get the input env vars
input=$(env | grep SECURITYC | grep -v WAIT_COUNT)

if [ $verbose = true ]; then
    echo
    echo "input:"
    echo "$input"
fi

# split the env vars by = then split by _
# and grap the app name
awk_cmd='{ split($1,var_names,"="); split(var_names[1],app_names,"_"); print app_names[2] }'
# TODO: this is fragile to user input, if they pass an extra _ before the app name

apps=$(echo "$input" | \
    awk "$awk_cmd" \
    | sort -u)

if [ $verbose = true ]; then
    echo
    echo "apps:"
    echo "$apps"
    echo
fi

function parse_env_config() {
    local var
    local result
    # string interpolate the name of the env var
    var="SECURITYC_${1}_${2}"
    # get the value of the env var itself
    # see https://www.tldp.org/LDP/abs/html/abs-guide.html#IVR
    result=$(eval "echo \$$(echo $var)")
    # return the result if it was parsed, otherwise an empty string
    if [ -n "$result" ]; then
        echo "$result"
    else
        echo ""
    fi
}

# run tls.sh for each set of args
for app in $apps; do
    # get the environmental variable values
    arg_ca_common_name=$(parse_env_config "${app}" "CA_COMMON_NAME")
    arg_cert_common_name=$(parse_env_config "${app}" "CERT_COMMON_NAME")
    arg_cert_ip=$(parse_env_config "${app}" "CERT_IP")
    arg_cert_domain=$(parse_env_config "${app}" "CERT_DOMAIN")
    arg_ca_out=$(parse_env_config "${app}" "CA_OUT")
    arg_key_out=$(parse_env_config "${app}" "KEY_OUT")
    arg_cert_out=$(parse_env_config "${app}" "CERT_OUT")


    # be explicit and check that all of the required
    # arguments are set
    if [ "$arg_cert_common_name" == "" ] \
        || [ "$arg_cert_out" == "" ] \
        || [ "$arg_key_out" == "" ] \
        || [ "$arg_ca_out" == "" ]; then
        echo "Missing argument for $app"
        echo "cert common name: $arg_cert_common_name"
        echo "cert out: $arg_cert_out"
        echo "key out: $arg_key_out"
        echo "ca out: $arg_ca_out"
        echo "skipping certificate generation"
        echo
    else
        # build the script arguments
        script_args="--ca-common-name ${arg_ca_common_name} --cert-common-name ${arg_cert_common_name}"
        script_args="${script_args} --ip ${arg_cert_ip} --domain ${arg_cert_domain}"
        script_args="${script_args} --ca-out ${arg_ca_out} --key-out ${arg_key_out} --cert-out ${arg_cert_out}"
        if [ $verbose = true ]; then
            # append verbose flag if verbose is true
            echo "successfully parsed all arguments"
            script_args="${script_args} -v"
            echo
            echo "calling $DIR/certstrap.sh ${script_args}"
            echo
        fi
        # invoke the script, don't quote as we
        # want the arguments to split
        $DIR/certstrap.sh ${script_args}

        echo "completed cerstrap for $app"
    fi
done

echo "done generating certs"
echo "exiting"

