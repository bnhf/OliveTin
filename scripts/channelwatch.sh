#!/bin/bash
# channelwatch.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

# legacy call: a single-digit $2 is the old Action's arg layout -- hand off to the old script and stop
[[ $2 =~ ^[0-9]$ ]] && {
  echo "ChannelWatch is no longer supported as an OliveTin Action. Please install it via Project One-Click instead"
  /config/channelwatch_old.sh "$1" 0
  exit 0
}

hostPort="$2"
hostDir="$5"
channelwatchSecretStorageKey="$4"
# "#" means: generate a key
[[ $channelwatchSecretStorageKey == "#" ]] && channelwatchSecretStorageKey=$(openssl rand -base64 48)

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"TZ=$3"
"CHANNELWATCH_SECRET_STORAGE_KEY=$channelwatchSecretStorageKey"
"HOST_DIR=$5"
)

synologyDirs=(
"$hostDir/channelwatch"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack
