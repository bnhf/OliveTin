#! /bin/bash

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"HOST_VNC_PORT=$4"
"VIDEO=$5"
"AUDIO=$6"
"TZ=$7"
"HOST_VOLUME=$8"
)

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
