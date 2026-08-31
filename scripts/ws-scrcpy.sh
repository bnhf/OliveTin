#!/bin/bash
# ws-scrcpy.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$3"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"DOMAIN=$2"
"HOST_PORT=$3"
"PORTAINER_HOST=$4"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
