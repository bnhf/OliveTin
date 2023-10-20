#!/bin/bash

dvr=$1
fileID=$2

recordingJSON=$(curl http://$dvr/dvr/files/$fileID)

programID=$(echo $recordingJSON | jq -r '.Airing.ProgramID')
programID=${programID//\//%2F}

curl -X DELETE http://$dvr/dvr/programs/$programID
