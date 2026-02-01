#!/bin/bash
# generatem3u.sh
# 2026.01.06

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')
logFile=/config/"$channelsHost"-"$channelsPort"_generatem3u_latest.log
source=$2
collection=$3
  [[ "$collection" == "none" ]] && collection=""
bitrate=$4
  [[ "$bitrate" == "none" ]] && bitrate="" || bitrate=$(echo "bitrate=$bitrate")
  [[ "$bitrate" == "bitrate=copy" ]] && bitrate="codec=copy"
filter=$5
  [[ "$filter" == "logos" ]] && logos="true" && filter="none"
  [[ "$filter" == "none" ]] && filter="" || filter=$(echo "filter=$filter")
format=$6
  [[ "$format" == "hls" ]] && format="" || format=$(echo "format=$format")
abr=$7
  [[ "$abr" == "true" ]] && abr="" || abr=$(echo "abr=$abr")
duration=$8
  [[ "$duration" == "none" ]] && duration=""
m3uFolder=/config/data/"$channelsHost"-"$channelsPort" && mkdir -p $m3uFolder
  [[ -z "$collection" ]] && m3uFile="$m3uFolder"/"$source".m3u
  [[ -n "$collection" ]] && m3uFile="$m3uFolder"/"${collection// /}".m3u
echo "m3uFile=$m3uFile" >&2

buildURL() {
  concatenator="?"
  m3uURL="http://$dvr/devices/$source/channels.m3u"
    [[ -n $bitrate ]] && m3uURL=$(echo "$m3uURL""$concatenator""$bitrate") && concatenator="&"
    [[ -n $filter ]] && m3uURL=$(echo "$m3uURL""$concatenator""$filter") && concatenator="&"
    [[ -n $format ]] && m3uURL=$(echo "$m3uURL""$concatenator""$format") && concatenator="&"
    [[ -n $abr ]] && m3uURL=$(echo "$m3uURL""$concatenator""$abr") && concatenator="&"
}

buildStreamURL() {
  concatenator="?"
  [[ -z $format ]] && streamURL="hls/master.m3u8" || streamURL="stream.mpg"
    [[ -n $bitrate ]] && streamURL=$(echo "$streamURL""$concatenator""$bitrate") && concatenator="&"
    [[ -n $filter ]] && streamURL=$(echo "$streamURL""$concatenator""$filter") && concatenator="&"
    [[ -n $format ]] && streamURL=$(echo "$streamURL""$concatenator""$format") && concatenator="&"
    [[ -n $abr ]] && streamURL=$(echo "$streamURL""$concatenator""$abr") && concatenator="&"
    [[ $concatenator == "?" ]] && streamURL=$(echo "$streamURL""$concatenator")
}

outputM3U() {
  echo -e "M3U used: $m3uURL\nCopy & Paste M3U from here or use: $m3uFile\nOptional access by URL at http://<host:port>/"$channelsHost"-"$channelsPort"/$source.m3u\n" > $logFile
  [[ -n $duration ]] && echo -e "Optional guide data URL: http://$dvr/devices/$source/guide/xmltv?duration=$duration\n"
  curl -s $m3uURL > $m3uFile
  cat $m3uFile >> $logFile
  cat $logFile
}

outputCollectionM3U() {
  collectionChannelIDs=$(curl -s http://$dvr/dvr/collections/channels | jq -r '.[] | select(.name == "'"$collection"'") | .items[]')
    [[ -z $collectionChannelIDs ]] \
    && echo "Channel Collection not found: $collection" \
    && exit 1 || IFS=$'\n' read -rd '' -a collectionChannelIDs <<< "$collectionChannelIDs"
  echo -e "M3U for Collection: $collection\nSource M3U used: $m3uURL\nCopy & Paste M3U from here or use: $m3uFile\nOptional access by URL at http://<host:port>/"$channelsHost"-"$channelsPort"/"${collection// /}".m3u\n" > $logFile
  [[ -n $duration ]] && echo -e "Optional guide data URL: http://$dvr/devices/$source/guide/xmltv?duration=$duration\n"
    allChannelsJSON=$(curl -s http://$dvr/devices/ANY/guide/now)
  allChannelsM3U=$(curl -s http://$dvr/devices/ANY/channels)
  [[ $logos ]] && allContentUploads=$(curl -s http://$dvr/dvr/uploads)
  echo -e "#EXTM3U\n" > $m3uFile

  for collectionChannelID in "${collectionChannelIDs[@]}"; do
    echo -e "\ncollectionChannelID=$collectionChannelID" >&2
    #collectionChannelNumber=$(echo "$allChannelsJSON" | jq -r '.[] | select(.Channel.ChannelID == "'"$collectionChannelID"'") | .Channel.Number')
    collectionChannelNumber=$(echo "$allChannelsJSON" | jq -r '[.[] | select(.Channel.ChannelID == "'"$collectionChannelID"'") | .Channel.Number][0]')
    echo "$allChannelsJSON" | jq -c '[.[] | select(.Channel.ChannelID == "'"$collectionChannelID"'") | .Channel.Number][0]' >&2
    echo "collectionChannelNumber=$collectionChannelNumber" >&2
    [[ "$collectionChannelNumber" == "null" || -z "$collectionChannelNumber" ]] && continue
    #[[ -z $filter ]] && collectionChannelM3U=$(echo "$allChannelsM3U" | jq -r '.[] | select(.GuideNumber == "'"$collectionChannelNumber"'") | "#EXTINF:-1 channel-id=\"\(.GuideNumber)\" tvg-id=\"\(.GuideNumber)\" tvg-chno=\"\(.GuideNumber)\" tvg-logo=\"\(.Logo)\" tvc-guide-stationid=\"\(.Station)\" tvg-name=\"\(.GuideName)\",\(.GuideName)\nhttp://'$dvr'/devices/ANY/channels/\(.GuideNumber)/'$streamURL'"')
    [[ -z $filter ]] && collectionChannelM3U=$(echo "$allChannelsM3U" | jq -r '[.[] | select(.GuideNumber == "'"$collectionChannelNumber"'") | "#EXTINF:-1 channel-id=\"\(.GuideNumber)\" tvg-id=\"\(.GuideNumber)\" tvg-chno=\"\(.GuideNumber)\" tvg-logo=\"\(.Logo)\" tvc-guide-stationid=\"\(.Station)\" tvg-name=\"\(.GuideName)\",\(.GuideName)\nhttp://'"$dvr"'/devices/ANY/channels/\(.GuideNumber)/'"$streamURL"'"][0]')
    [[ $logos ]] && contentID=$(echo "$allContentUploads" | jq -r --arg number "$collectionChannelNumber" '.[] | select(.Name | test("^" + $number + "\\.(png|jpg)$")).ID') \
      && collectionChannelM3U=$(echo "$allChannelsM3U" | jq -r --arg contentID "$contentID" --arg dvr "$dvr" --arg channelNumber "$collectionChannelNumber" '.[] | select(.GuideNumber == $channelNumber) | "#EXTINF:-1 channel-id=\"\(.GuideNumber)\" tvg-id=\"\(.GuideNumber)\" tvg-chno=\"\(.GuideNumber)\" tvg-logo=\"https://\($dvr)/dvr/uploads/\($contentID)/content\" tvc-guide-stationid=\"\(.Station)\" tvg-name=\"\(.GuideName)\",\(.GuideName)"')
    echo "$allChannelsM3U" | jq -c --arg contentID "$contentID" --arg dvr "$dvr" --arg channelNumber "$collectionChannelNumber" '.[] | select(.GuideNumber == $channelNumber)' >&2
    [[ -n $collectionChannelM3U ]] && echo -e "$collectionChannelM3U\n" | awk '!seen[$0]++' | tr -s '\n' | sed 's/#EXTINF/\n#EXTINF/g' >> $m3uFile
  done

  cat $m3uFile >> $logFile
  cat $logFile
}

main() {
  buildURL
  [[ -n $collection ]] && buildStreamURL
  [[ -z $collection ]] && outputM3U || outputCollectionM3U
}

main
