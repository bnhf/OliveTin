#!/bin/bash
# tubearchivist.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
hostDir="$9"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"ES_PORT=$3"
"REDIS_PORT=$4"
"TA_HOST=$5"
"TA_USERNAME=$6"
"TA_PASSWORD=$7"
"TZ=$8"
"HOST_DIR=$9"
)

synologyDirs=(
"$hostDir/tubearchivist/media"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack
