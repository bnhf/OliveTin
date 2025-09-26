#!/bin/bash
# pinchflat.sh
# 2025.09.26

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
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
"VIDEOS_SHARE=$5"
)

synologyDirs=(
"$4/pinchflat"
)

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
