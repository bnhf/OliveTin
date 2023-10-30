#!/bin/bash

dvr=$1
fileID=$2
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_markforrerecord_latest.log

recordingJSON=$(curl http://$dvr/dvr/files/$fileID)

programID=$(echo $recordingJSON | jq -r '.Airing.ProgramID')
programID=${programID//\//%2F}
programTitle=$(echo $recordingJSON | jq -r '.Airing.Title')
programEpisode=$(echo $recordingJSON | jq -r '.Airing.EpisodeTitle')
programPath=$(echo $recordingJSON | jq -r '.Path')

echo -e "$programTitle - $programEpisode has been marked for re-recording on $dvr:\n" > $logFile
echo -e "$programPath \n" >> $logFile
curl -X DELETE http://$dvr/dvr/programs/$programID >> $logFile
cat $logFile
