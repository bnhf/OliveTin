#!/bin/bash
# tailscale.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

envVars=(
"TAG=$1"
"TS_SOCKET=$2"
"TS_EXTRA_ARGS=$3"
"TS_STATE_DIR=$4"
"HOST_DIR=$5"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
