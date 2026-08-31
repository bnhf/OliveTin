#!/bin/bash
# channels-app-remote.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
# current Channels app clients as hostname:local_ip, comma-joined
channelsAppClients=$(curl -s "http://$dvr/dvr/clients/info" | jq -r '[.[] | "\(.hostname):\(.local_ip)"] | join(",")')

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"CHANNELS_APP_CLIENTS=$channelsAppClients"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
