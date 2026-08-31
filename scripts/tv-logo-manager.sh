#!/bin/bash
# tv-logo-manager.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$2"
hostDir="$7"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$1"
"HOST_PORT=$2"
"CLOUDINARY_CLOUD_NAME=$3"
"CLOUDINARY_API_KEY=$4"
"CLOUDINARY_API_SECRET=$5"
"TZ=$6"
"HOST_DIR=$7"
)

synologyDirs=(
"$hostDir/tv-logo-manager"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack
