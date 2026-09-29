#!/bin/bash
# ah4c-minimal.sh
# 2026.09.22

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

hostPort="$5"
hostDir="$8"
ah4cContainer=$(emptyIfHash "$9")

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort" "ah4c$ah4cContainer"

envVars=(
"TAG=$1"
"CONTAINER_NAME=ah4c$ah4cContainer"
"HOSTNAME=ah4c$ah4cContainer"
"DOMAIN=$2"
"DOCKER_RUNTIME=$3"
"GPU_DEVICE=$4"
"HOST_PORT=$5"
"NVIDIA_VISIBLE_DEVICES=$6"
"NVIDIA_DRIVER_CAPABILITIES=$7"
"HOST_DIR=$8"
)

synologyDirs=(
"$hostDir/ah4c$ah4cContainer/scripts"
"$hostDir/ah4c$ah4cContainer/m3u"
"$hostDir/ah4c$ah4cContainer/adb"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp "http://$extensionURL" "ah4c$ah4cContainer"

greenEcho "\nah4c$ah4cContainer is up at http://$extensionURL" \
  "-- open its Settings page there to configure tuners, the Channels DVR connection, alerts, and everything else, then add its M3U as a CDVR Custom Channels source."
