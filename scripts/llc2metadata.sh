#!/bin/bash
# llc2metadata.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_llc2metadata_latest.log
fileID="$2"
dvrDir="$channelsHost-$channelsPort"

echo "Retrieving JSON data for FileID $fileID...\n"
recordingName=$(curl -s "http://$dvr/dvr/files/$fileID" | jq -r '.Path' | sed 's|\\|/|g')
recordingLLC="${recordingName%.mpg}-proj.llc"
llcChapters=$(cat "/mnt/$dvrDir/$recordingLLC")
llcCommercials=$(echo "$llcChapters" | awk -F'(start: | end: )' '{print $2}' | tr -d '\n' | sed 's/,$//')

echo "\n\nRetrieving LosslessCut chapter markers for $recordingName...\n" > "$logFile"
echo "$llcChapters\n" >> "$logFile"

echo "POSTing updated commercial skip markers to $recordingName...\n" >> "$logFile"
echo "[$llcCommercials]\n" >> "$logFile"

curl -s -XPOST "http://$dvr/dvr/files/$fileID/comskip/edit?source=local" --data-raw "[$llcCommercials]"

echo "Regenerating video index...\n" >> $logFile
curl -s -XPUT "http://$dvr/dvr/files/$fileID/m3u8"

cat "$logFile"
