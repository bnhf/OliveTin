#!/bin/bash
# cc4c.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$3"
cdvrStartingChannel="${15}"
# "none" -> no extra M3U to merge in
[[ "${16}" == "none" ]] && m3uFile="" || m3uFile="${16}"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"

envVars=(
"TAG=$2"
"HOST_PORT=$3"
"CC4C_PORT=$4"
"HOST_VNC_PORT=$5"
"VIDEO_BITRATE=$6"
"AUDIO_BITRATE=$7"
"FRAMERATE=$8"
"VIDEO_WIDTH=$9"
"VIDEO_HEIGHT=${10}"
"VIDEO_CODEC=${11}"
"AUDIO_CODEC=${12}"
"TZ=${13}"
"DEVICES=${14}"
)

[[ -n $m3uFile ]] && textM3U=$(awk 'NR > 2' /config/cc4c_"$m3uFile".m3u | sed "s/localhost:5589/$extensionURL/g" | sed ':a;N;$!ba;s/\n/\\n/g')

# text blob carries JSON-escaped \" and \n, so this heredoc stays local rather than
# going through a one-clickChannelJson text= kwarg (bash would strip the backslashes)
customChannels() {
cat <<EOF
{
  "name": "cc4c",
  "type": "HLS",
  "source": "Text",
  "url": "",
  "text": "#EXTM3U\n\n#EXTINF:-1 channel-id=\"weatherscan\",Weatherscan\nchrome://$extensionURL/stream?url=https://v2.weatherscan.net\n\n$textM3U",
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
one-clickRegisterSource cc4c "$(customChannels)"
