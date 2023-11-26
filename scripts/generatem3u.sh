#!/bin/bash

set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_generatem3u_latest.log
source=$2
bitrate=$3
  [[ "$bitrate" == "none" ]] && bitrate="" || bitrate=$(echo "bitrate=$bitrate")
  [[ "$bitrate" == "bitrate=copy" ]] && bitrate="codec=copy"
filter=$4
  [[ "$filter" == "none" ]] && filter="" || filter=$(echo "filter=$filter")
format=$5
  [[ "$format" == "hls" ]] && format="" || format=$(echo "format=$format")
abr=$6
  [[ "$abr" == "true" ]] && abr="" || abr=$(echo "abr=$abr")
duration=$7
  [[ "$duration" == "none" ]] && duration=""
concatenator="?"
m3uFolder=/config/data && mkdir -p $m3uFolder
m3uFile="$m3uFolder"/"$channelsHost"-"$channelsPort".m3u

buildURL() {
  m3uURL="http://$dvr/devices/$source/channels.m3u"
    [[ -n $bitrate ]] && m3uURL=$(echo "$m3uURL""$concatenator""$bitrate") && concatenator="&"
    [[ -n $filter ]] && m3uURL=$(echo "$m3uURL""$concatenator""$filter") && concatenator="&"
    [[ -n $format ]] && m3uURL=$(echo "$m3uURL""$concatenator""$format") && concatenator="&"
    [[ -n $abr ]] && m3uURL=$(echo "$m3uURL""$concatenator""$abr") && concatenator="&"
}

outputM3U() {
echo -e "M3U used: $m3uURL\n" > $logFile
[[ -n $duration ]] && echo -e "Optional guide data URL: http://$dvr/devices/$source/guide/xmltv?duration=$duration\n"
curl $m3uURL > $m3uFile
cat $m3uFile >> $logFile
cat $logFile
}

main() {
  buildURL
  outputM3U
}

main