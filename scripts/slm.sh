#!/bin/bash
# slm.sh
# 2025.04.01

set -x

extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
dirsFile="/tmp/$extension.dirs"

envVars=(
"TAG=$1"
"SLM_PORT=$2"
"TIMEZONE=$3"
"SLM_HOST_FOLDER=$4"
"CHANNELS_FOLDER=$5"
)

synologyDirs=(
"$4"
)

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
