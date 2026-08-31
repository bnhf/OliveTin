#!/bin/bash
# vlc-bridge-uk.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"ITV_USER=$4"
"ITV_PASS=$5"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
