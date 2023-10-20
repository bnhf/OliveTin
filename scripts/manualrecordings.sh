#!/bin/bash

dvr="$1"
name="$2"
channel="$3"
time=$(date -d "$4" +%s)
duration=$(("$5" * 60))
summary="$6"
  [[ $summary == "none" ]] && summary=""
genres=$(echo "\"$7"\" | sed 's/,/","/g' | sed 's/" /"/g')
  [[ $genres == "\"none"\" ]] && genres=""
image="$8"
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

curl -v --data-binary "$recordingJSON" http://$dvr/dvr/jobs/new
