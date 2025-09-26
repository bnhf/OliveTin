#!/bin/bash
# youtub3r.sh
# 2025.09.26

dvr="$1"
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
"TAG=$2"
"SERVER_HOST=$dvr"
"WAIT_IN_SECONDS=$3"
"YOUTUBE_SHARE=$4"
)

#synologyDirs=(
#"$4/pinchflat"
#)

printf "%s\n" "${envVars[@]}" > $envFile
#printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
