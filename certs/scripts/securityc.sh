#!/bin/bash

set -eou pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

verbose=false
while [[ "$#" -gt 0 ]]; do case $1 in
  -v|--verbose) verbose=true;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

# get the input env vars
input=$(env | grep SECURITYC)

if [ $verbose = true ]; then
    echo
    echo "input:"
    echo "$input"
fi

# split the env vars by = then split by _
# and grap the app name
awk_cmd='{ split($1,var_names,"="); split(var_names[1],app_names,"_"); print app_names[2]}'
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
    echo "$result"
}

# run tls.sh for each set of args
for app in $apps; do
    # get the environmental variable values
    arg_alt_name=$(parse_env_config "${app}" "ALT_NAME")
    arg_cert_out=$(parse_env_config "${app}" "CERT_OUT")
    arg_key_out=$(parse_env_config "${app}" "KEY_OUT")
    arg_config_path=$(parse_env_config "${app}" "CONFIG_PATH")


    # be explicit and check if any of the values are not set
    if [ "$arg_alt_name" == "" ] \
        || [ "$arg_cert_out" == "" ] \
        || [ "$arg_key_out" == "" ] \
        || [ "$arg_config_path" == "" ]; then
        echo "Missing argument for $app"
        echo "cert out: $arg_cert_out"
        echo "key out: $arg_key_out"
        echo "config path: $arg_config_path"
        echo "skipping certificate generation"
        echo
    else
        # build the script arguments
        script_args="-an ${arg_alt_name} -co ${arg_cert_out} -ko ${arg_key_out} -c ${arg_config_path}"
        if [ $verbose = true ]; then
            # append verbose flag if verbose is true
            echo "successfully parsed all arguments"
            script_args="${script_args} -v"
            echo
            echo "calling $DIR/tls.sh ${script_args}"
            echo
        fi
        # invoke the script, don't quote as we
        # want the arguments to split
        $DIR/tls.sh ${script_args}
    fi
done
