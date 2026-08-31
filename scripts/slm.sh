#!/bin/bash
# slm.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
hostFolder="$4"

# one-clickPreflight <SLM_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"SLM_PORT=$2"
"TIMEZONE=$3"
"SLM_HOST_FOLDER=$4"
"CHANNELS_FOLDER=$5"
)

synologyDirs=(
"$hostFolder"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack
