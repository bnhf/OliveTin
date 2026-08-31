#!/bin/bash
# pinchflat.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
hostDir="$4"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"TZ=$3"
"HOST_DIR=$4"
"VIDEOS_SHARE=$5"
)

synologyDirs=(
"$hostDir/pinchflat"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack
