#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_marknocommercials_latest.log
fileID=$2

echo "Removing commercial markers from recording with File ID: $fileID on DVR: $dvr" > $logFile
curl -XPOST "http://$dvr/dvr/files/$fileID/comskip/edit?source=local" --data-raw "[]" >> $logFile
echo -e "\n\nRefreshing Metadata" >> $logFile
curl -XPUT "http://$dvr/dvr/files/$fileID/reprocess" >> $logFile
echo -e "\n\nRegenerating Video Index" >> $logFile
curl -XPUT "http://$dvr/dvr/files/$fileID/m3u8" >> $logFile
cat $logFile