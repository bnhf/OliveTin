#!/bin/bash
# pluto.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
