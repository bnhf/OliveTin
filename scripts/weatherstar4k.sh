#!/bin/bash
# weatherstar4k.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
cdvrStartingChannel="$5"
cc4cHostPort="$6"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"TZ=$4"
)

# text blob carries JSON-escaped \" and \n, so this heredoc stays local rather than
# going through a one-clickChannelJson text= kwarg (bash would strip the backslashes)
customChannels() {
cat <<EOF
{
  "name": "WeatherStar4k",
  "type": "HLS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:-1 channel-id=\"WS4KP\" tvg-logo=\"https://raw.githubusercontent.com/netbymatt/ws4kp/main/server/images/logos/logo192.png\",WeatherStar 4000+\nchrome://$cc4cHostPort/stream?url=http://$extensionURL",
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
one-clickRegisterSource weatherstar4k "$(customChannels)"
