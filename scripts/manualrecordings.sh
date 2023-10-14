#!/bin/bash

name="$1"
channel="$2"
time=$(date -d "$3" +%s)
duration=$(("$4" * 60))
summary="$5"
  [[ $summary == "none" ]] && summary=""
genres=$(echo "\"$6"\" | sed 's/,/","/g' | sed 's/" /"/g')
  [[ $genres == "\"none"\" ]] && genres=""
image="$7"
source="manual"

recordingJob() {
cat <<EOF
{
    "Name": "$name",
    "Time": $time,
    "Duration": $duration,
    "Channels": ["$channel"],
    "Airing": {
        "Source": "$source",
        "Channel": "$channel",
        "Time": $time,
        "Duration": $duration,
        "Title": "$name",
        "Summary": "$summary",
        "Genres": [$genres],
        "SeriesID": "$source/$channel",
        "Image": "$image"
    }
}
EOF
}

recordingJSON=$(echo -n "$(recordingJob)" | tr -d '\n')

curl -v --data-binary "$recordingJSON" http://$CHANNELS_DVR/dvr/jobs/new
