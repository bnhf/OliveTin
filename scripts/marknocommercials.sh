#!/bin/bash
# marknocommercials.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_marknocommercials_latest.log
fileID=$2

echo "Removing commercial markers from recording with File ID: $fileID on DVR: $dvr" > $logFile
curl -s -XPOST "http://$dvr/dvr/files/$fileID/comskip/edit?source=local" --data-raw "[]" >> $logFile
echo -e "\n\nRefreshing Metadata" >> $logFile
curl -s -XPUT "http://$dvr/dvr/files/$fileID/reprocess" >> $logFile
echo -e "\n\nRegenerating Video Index" >> $logFile
curl -s -XPUT "http://$dvr/dvr/files/$fileID/m3u8" >> $logFile
cat $logFile
