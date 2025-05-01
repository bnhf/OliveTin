#!/bin/bash
# organizr.sh
# 2025.04.01

set -x

extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
dirsFile="/tmp/$extension.dirs"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"TZ=$3"
"HOST_DIR=$4"
)

synologyDirs=(
"$4/organizr"
)

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
