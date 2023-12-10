#!/bin/bash

#set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_generatem3u_latest.log
source=$2
collection=$3
  [[ "$collection" == "none" ]] && $collection=""
bitrate=$4
  [[ "$bitrate" == "none" ]] && bitrate="" || bitrate=$(echo "bitrate=$bitrate")
  [[ "$bitrate" == "bitrate=copy" ]] && bitrate="codec=copy"
filter=$5
  [[ "$filter" == "none" ]] && filter="" || filter=$(echo "filter=$filter")
format=$6
  [[ "$format" == "hls" ]] && format="" || format=$(echo "format=$format")
abr=$7
  [[ "$abr" == "true" ]] && abr="" || abr=$(echo "abr=$abr")
duration=$8
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

outputCollectionM3U() {
  collectionChannelIDs=$(curl http://$dvr/dvr/collections/channels | jq -r '.[] | select(.name == "'"$collection"'") | .items[]')
    [[ -z $collectionChannelIDs ]] \
    && echo "Channel Collection not found: $collection" \
    && exit 1
  echo -e "M3U for Collection: $collection\nSource M3U used: $m3uURL\nCopy & Paste M3U from here or use: $m3uFile\n" > $logFile
  [[ -n $duration ]] && echo -e "Optional guide data URL: http://$dvr/devices/$source/guide/xmltv?duration=$duration\n"
    allChannelsJSON=$(curl http://$dvr/devices/ANY/guide/now)
  allChannelsM3U=$(curl $m3uURL)
  echo -e "#EXTM3U\n" > $m3uFile

  for collectionChannelID in ${collectionChannelIDs[@]}; do
    collectionChannelNumber=$(echo "$allChannelsJSON" | jq -r '.[] | select(.Channel.ChannelID == "'"$collectionChannelID"'") | .Channel.Number')
    collectionChannelM3U=$(echo "$allChannelsM3U" | grep -A 1 -E "tvg-chno=\"$collectionChannelNumber\"")
    [[ -n $collectionChannelM3U ]] && echo -e "$collectionChannelM3U\n" >> $m3uFile
  done

  cat $m3uFile >> $logFile
  cat $logFile
}

main() {
  buildURL
  [[ -z $collection ]] && outputM3U || outputCollectionM3U
}

main