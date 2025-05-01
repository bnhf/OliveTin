#!/bin/bash
# filebot.sh
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
"DARK_MODE=$3"
"HOST_DIR=$4"
"DVR_SHARE=$5"
"VOL_EXTERNAL=$6"
"VOL_NAME=$7"
)

synologyDirs=(
"$4/filebot"
)

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
