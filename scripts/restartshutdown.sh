#!/bin/bash
# restartshutdown.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_restartshutdown_latest.log
urlAction=$2

echo -e "The following restart or shutdown action is being sent to $dvr: $urlAction \n" > $logFile
curl -s -XPUT http://$dvr/updater/$urlAction >> $logFile
cat $logFile
