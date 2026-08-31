#!/bin/bash
# mediainfo.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
hostDir="$4"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"DARK_MODE=$3"
"HOST_DIR=$4"
"DVR_SHARE=$5"
"VOL_EXTERNAL=$6"
"VOL_NAME=$7"
)

synologyDirs=(
"$hostDir/mediainfo"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack
