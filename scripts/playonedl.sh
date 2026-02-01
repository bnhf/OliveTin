#!/bin/bash
# playonedl.sh
# 2026.01.18
#     Chapter #0:0: start 0.000000, end 1290.013333
#       first   _     _     start    _     end

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenEcho() { echo -e "\033[0;32m$1\033[0m ${*:2}"; }

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
dvrDir="$channelsHost-$channelsPort"
playonPath="$2"
playonSingleMP4="$3"
playonMultipleMP4s=$3

wildcardArgumentHandler() {
if [[ "$playonSingleMP4" == *'?'* || "$playonSingleMP4" == *'*'* ]]; then
  playonMP4s=()
  for playonMP4 in $playonMultipleMP4s; do
    playonMP4s+=("$playonMP4")
  done
else
  playonMP4s=("$playonSingleMP4")
fi
}

commercialChapters2EDL() {
for playonMP4 in "${playonMP4s[@]}"; do
  ffmpeg -i "$playonMP4" 2> /tmp/playonedl.tmp
  playonEDL="${playonMP4%.mp4}.edl"  # Remove .mp4 from the filename and add .edl
  [ -f "$playonEDL" ] && rm "$playonEDL"

    while read -r first _ _ start _ end; do
      if [[ $first = Chapter ]]; then
        read  # discard line with Metadata:
        read _ _ chapter
        if [ "$chapter" = "Advertisement" ]; then
          echo -e "${start%?}\t$end\t3" >> "$playonEDL"
        fi
      fi
    done </tmp/playonedl.tmp

  rm /tmp/playonedl.tmp
  echo -e "\n$playonEDL created for:"
  echo -e "$playonMP4 with the following contents:\n"
  cat "$playonEDL"
done
}

main() {
  cd "/mnt/$dvrDir/PlayOn/$playonPath"
  wildcardArgumentHandler
  commercialChapters2EDL
  cd /
}

main
