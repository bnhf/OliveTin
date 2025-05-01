#!/bin/bash
# yttv_m3u_json.sh
# 2025.04.21

#set -x

dvr=$1
channelsHost=$(echo "$dvr" | awk -F: '{print $1}')
channelsPort=$(echo "$dvr" | awk -F: '{print $2}')
portainerHost="$PORTAINER_HOST"
sfsPort=$(docker inspect -f '{{(index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort}}' static-file-server)
datasetType="$2"
sourceCSV="$3"
  [[ ( "$datasetType" == "m3u" || "$datasetType" == "json" ) && -z $sourceCSV ]] && echo "A source CSV file must be specified to generate an M3U or JSON file" && exit 0
  [[ -n $sourceCSV && ! -f /config/$sourceCSV ]] && echo "No CSV file with the name /config/$sourceCSV found" && exit 0
adbtunerPackage="$4"
adbtunerAlternate="$5"
hostedM3U="/config/data/$channelsHost-$channelsPort/YouTubeTV.m3u"
hostedJSON="/config/data/$channelsHost-$channelsPort/YouTubeTV.json"
  mkdir -p "/config/data/$channelsHost-$channelsPort"
sourceJSON="/config/yttv_m3u_json.json"
  [[ -n $sourceCSV ]] && sed 's/\?.*$//' /config/"$sourceCSV" | mlr --icsv --ojson --jlistwrap cat | jq . > "$sourceJSON"
templateCSV="/config/yttv_template.csv"

createM3U() {
  {
    echo -e "#EXTM3U\n"
    jq -r '
      map(select(.url != ""))[] 
      | "#EXTINF:-1 channel-id=\"\(.callsign)\" tvc-guide-stationid=\"\(.stationid)\",\(.name)\nchrome://'"$portainerHost"':5589/stream?url=\(.url)\n"
    ' "$sourceJSON"
  } > "$hostedM3U"

  echo "This file can be accessed by URL at http://$portainerHost:$sfsPort/$channelsHost-$channelsPort/YouTubeTV.m3u"
  echo -e "Or, copy and paste the contents below as text in your CDVR Custom Channels Source:\n"
  cat "$hostedM3U"
}

createJSON() {
  jq '
    [ map(select(.url != ""))[] 
      | {
          provider_name: "YTTV",
          number: null,
          name: .name,
          url: .url,
          package_name: "'"$adbtunerPackage"'",
          alternate_package_name: "'"$adbtunerAlternate"'",
          compatibility_mode: false,
          tvc_guide_stationid: .stationid,
          guide_offset_hours: null
        }
    ]' "$sourceJSON" > "$hostedJSON"
  echo "This file can be accessed by URL at http://$portainerHost:$sfsPort/$channelsHost-$channelsPort/YouTubeTV.json"
  echo -e "Or, copy and paste the contents below into a .json file:\n"
  cat "$hostedJSON"
}

outputCSV() {
  echo -e "Copy and paste the CSV dataset below (including the header row) into a text editor.
Then, open YouTube TV in a browser window, and naviagte to the \"Live\" view. Sort A-Z.\n
Position your browser side-by-side with the text editor. Now, you should be able to drag 
the now-showing grid item for a given channel over to the end of the CSV \"record\" for that 
channel. No need to shorten the URL, the part after the question mark will be stripped.\n
When you've added the URLs for the channels you'd like available in cc4c or ADBTuner, save
your work and place this new csv file in the directory bound to OliveTin's /config directory.
Run this action again, select M3U or CSV and specify the filename for your CSV file.\n"
  cat "$templateCSV"
}

main() {
  [[ "$datasetType" == "csv" ]] && outputCSV && exit 0
  [[ "$datasetType" == "m3u" ]] && createM3U || createJSON
}

main
