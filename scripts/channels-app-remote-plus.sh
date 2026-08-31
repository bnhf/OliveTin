#!/bin/bash
# channels-app-remote-plus.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
# all configured Channels DVRs (primary + alternates), comma-joined
dvrs=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)
channelsDVRs=$(IFS=,; echo "${dvrs[*]}")

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"CHANNELS_DVR_SERVERS=$channelsDVRs"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
