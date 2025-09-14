#!/bin/bash
# tv-logo-manager.sh
# 2025.09.13

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
"CLOUDINARY_CLOUD_NAME=$3"
"CLOUDINARY_API_KEY=$4"
"CLOUDINARY_API_SECRET=$5"
"TZ=$6"
"HOST_DIR=$7"
)

synologyDirs=(
"$7/tv-logo-manager"
)

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
