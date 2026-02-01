#!/bin/bash
# comskipignore.sh
# 2026.01.16

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_comskipignore_latest.log
channel=$2
curlAction=$3

echo -e "Channel $channel had its Comskip status changed via a curl -X $curlAction on $dvr:\n" > $logFile
curl -s -X $curlAction http://$dvr/comskip/ignore/channel/$channel >> $logFile
cat $logFile
