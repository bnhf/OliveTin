#!/bin/bash
# channelwatch.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

extension=$(basename "$0")
extension=${extension%.sh}
cp /config/$extension.env /tmp
envFile="/tmp/$extension.env"
dirsFile="/tmp/$extension.dirs"
secondArgument="$2"
  [[ $secondArgument =~ ^[0-9]$ ]] && echo "ChannelWatch is no longer supported as an OliveTin Action. Please install it via Project One-Click instead" \
  && /config/channelwatch_old.sh $1 0 && exit 0

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"HOST_DIR=$3"
)

synologyDirs=(
"$3/channelwatch"
)

printf "%s\n" "${envVars[@]}" > $envFile
printf "%s\n" "${synologyDirs[@]}" > $dirsFile

sed -i '/=#/d' $envFile

/config/portainerstack.sh $extension

[[ $? == 1 ]] && exit 1 || exit 0
