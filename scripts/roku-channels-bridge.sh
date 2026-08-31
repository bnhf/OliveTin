#!/bin/bash
# roku-channels-bridge.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"ENCODING_MODE=$4"
"AUDIO_BITRATE=$5"
"AUDIO_CHANNELS=$6"
"ENABLE_DEBUG_LOGGING=$7"
"HOST_VOLUME=$8"
"DEVICES=$9"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
