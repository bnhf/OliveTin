#!/bin/bash
# ah4c_directv_grabber.sh
# 2026.03.30

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

allchannelsGuideJSON=$(cat)
deepLinks="$1"

generateM3U() {
  printf '%s\n' "$allchannelsGuideJSON" \
  | jq -r --arg deepLinks "${deepLinks:-true}" '
    "#EXTM3U",
    "",
    (
      (.channelInfoList
       | group_by(.channelNumber | tonumber)
       | map(
           if length == 1 then .[0]
           else
             to_entries | map(
               if .key == 0 then .value
               else .key as $k | .value | .channelNumber = (.channelNumber + "." + ($k | tostring))
               end
             )
           end
         )
       | flatten
      )[]
      | "#EXTINF:-1 channel-id=\"\(.channelNumber)\" channel-number=\"\(.channelNumber)\" tvc-guide-stationid=\"\(.externalListingId // "")\",\(.channelName)",
        "http://{{ .IPADDRESS }}/play/tuner/\(if $deepLinks == "false" then .channelNumber else "\(.callSign)~\(.resourceId)" end)",
        ""
    )
  '
}

main() {
  generateM3U
}

main
