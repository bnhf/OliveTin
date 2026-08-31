#!/bin/bash
# adbtuner.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$4"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"DOMAIN=$3"
"HOST_PORT=$4"
"KNOWN_STREAM_DEFAULT_TIMEOUT=$5"
"HOST_VOLUME=$6"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
