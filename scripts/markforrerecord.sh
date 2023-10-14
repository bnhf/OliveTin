#!/bin/bash

fileID=$1

recordingJSON=$(curl http://$CHANNELS_DVR/dvr/files/$fileID)

programID=$(echo $recordingJSON | jq -r '.Airing.ProgramID')
programID=${programID//\//%2F}

curl -X DELETE http://$CHANNELS_DVR/dvr/programs/$programID
