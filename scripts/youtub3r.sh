#!/bin/bash
# youtub3r.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"

envVars=(
"TAG=$2"
"SERVER_HOST=$dvr"
"WAIT_IN_SECONDS=$3"
"YOUTUBE_SHARE=$4"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
