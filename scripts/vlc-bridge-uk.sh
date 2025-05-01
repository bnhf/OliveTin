#!/bin/bash
# vlc-bridge-uk.sh
# 2025.04.01

set -x

dvr="$1"
extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"ITV_USER=$4"
"ITV_PASS=$5"
)

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
