#!/bin/bash
# multichannelview.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$4"
cdvrStartingChannel="$6"
multiviewName="$7"
ch1="$8"; ch2="$9"; ch3="${10}"; ch4="${11}"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"

# resolve the four channel IDs to names for the guide blurb
allChannelsM3U=$(curl -s "http://$dvr/devices/ANY/channels.m3u?format=ts&codec=copy")
channelIDs=($ch1 $ch2 $ch3 $ch4)
for channelID in "${channelIDs[@]}"; do
  channelName=$(echo "$allChannelsM3U" | awk -v channelID="$channelID" '
    index($0, "channel-id=\""channelID"\"") {
      match($0, /tvg-name="([^"]+)"/, m)
      if (m[1]) print m[1]
      exit
    }')
  channelIDsNames+=": ${channelID} ${channelName} "
done
multiviewChannels="Mosaic of $channelIDsNames"

envVars=(
"TAG=$2"
"DEVICES=$3"
"HOST_PORT=$4"
"CDVR_HOST=${dvr%%:*}"
"CDVR_PORT=${dvr##*:}"
"CODEC=$5"
)

# text blob carries JSON-escaped \" so this heredoc stays local
customChannels() {
cat <<EOF
{
  "name": "Multichannel View",
  "type": "MPEG-TS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:-1 tvg-id=\"MCH\" tvc-guide-placeholders=\"7200\" tvc-guide-title=\"$multiviewChannels\" tvc-guide-description=\"$multiviewChannels\" tvc-guide-art=\"https://i.postimg.cc/pdCcpxMM/Multichannel-View.png\" tvg-logo=\"https://i.postimg.cc/pdCcpxMM/Multichannel-View.png\" group-title=\"HD\",$multiviewName\nhttp://$extensionURL/combine?ch=$ch1&ch=$ch2&ch=$ch3&ch=$ch4",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$cdvrIgnoreM3UNumbers",
  "start_number": "$cdvrStartingChannel",
  "logos": "",
  "xmltv_url": "",
  "xmltv_refresh": "3600"
}
EOF
}

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <CDVR source slug> <channel JSON>
one-clickRegisterSource multichannelview "$(customChannels)"
