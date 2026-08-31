#!/bin/bash
# threadfin.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
hostDir="$6"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"PUID=$3"
"PGID=$4"
"TZ=$5"
"HOST_DIR=$6"
)

synologyDirs=(
"$hostDir/threadfin/conf"
"$hostDir/threadfin/temp"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack
