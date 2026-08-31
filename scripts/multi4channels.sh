#!/bin/bash
# multi4channels.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
cdvrChannelNumber="$5"
rtpPort="$8"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"WEB_PAGE_PORT=$4"
"CDVR_HOST=${dvr%%:*}"
"CDVR_PORT=${dvr##*:}"
"CDVR_CHNLNUM=$5"
"OUTPUT_FPS=$6"
"RTP_HOST=$7"
"RTP_PORT=$8"
"HOST_VOLUME=$9"
)

# text blob carries JSON-escaped \" so this heredoc stays local
customChannels() {
cat <<EOF
{
  "name": "Multi4Channels",
  "type": "HLS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:0 channel-id=\"M4C\" tvg-id=\"$cdvrChannelNumber\" tvg-chno=\"$cdvrChannelNumber\" tvc-guide-placeholders=\"7200\" tvc-guide-title=\"Start a Stream At $extensionURL.\" tvc-guide-description=\"Visit Multi4Channels Web Page to Start a Stream ($extensionURL).\" tvc-guide-art=\"https://i.postimg.cc/xCy2v22X/IMG-3254.png\" tvg-logo=\"https://i.postimg.cc/xCy2v22X/IMG-3254.png\" tvc-guide-stationid=\"\" tvg-name=\"Multi4Channels\" group-title=\"HD\",M4C\nudp://0.0.0.0:$rtpPort",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "",
  "start_number": "",
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
one-clickRegisterSource multi4channels "$(customChannels)"
