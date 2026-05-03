#!/bin/bash
# ws-scrcpy.sh
# 2026.04.23

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"

envVars=(
"TAG=$1"
"DOMAIN=$2"
"HOST_PORT=$3"
"PORTAINER_HOST=$4"
)

printf "%s\n" "${envVars[@]}" > $envFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
