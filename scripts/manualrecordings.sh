#!/bin/bash
# manualrecordings.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

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
type="$9"

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

recordingJobMovie() {
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
        "MovieID": "$source/$channel",
        "Image": "$image",
        "Categories": ["Movie"]
    }
}
EOF
}

[[ "$type" == "tv" ]] \
  && recordingJSON=$(echo -n "$(recordingJob)" | tr -d '\n')
[[ "$type" == "movie" ]] \
  && recordingJSON=$(echo -n "$(recordingJobMovie)" | tr -d '\n')

curl -s -v --data-binary "$recordingJSON" http://$dvr/dvr/jobs/new
