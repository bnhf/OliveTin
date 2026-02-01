#!/bin/bash
# markforrerecord.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
fileID=$2
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_markforrerecord_latest.log

recordingJSON=$(curl -s http://$dvr/dvr/files/$fileID)

programID=$(echo $recordingJSON | jq -r '.Airing.ProgramID')
programID=${programID//\//%2F}
programTitle=$(echo $recordingJSON | jq -r '.Airing.Title')
programEpisode=$(echo $recordingJSON | jq -r '.Airing.EpisodeTitle')
programPath=$(echo $recordingJSON | jq -r '.Path')

echo -e "$programTitle - $programEpisode has been marked for re-recording on $dvr:\n" > $logFile
echo -e "$programPath \n" >> $logFile
curl -s -X DELETE http://$dvr/dvr/programs/$programID >> $logFile
cat $logFile
