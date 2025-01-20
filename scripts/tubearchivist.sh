#!/bin/bash

set -x

extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"ES_PORT=$3"
"REDIS_PORT=$4"
"TA_HOST=$5"
"TA_USERNAME=$6"
"TA_PASSWORD=$7"
"TZ=$8"
"HOST_DIR=$9"
)

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
