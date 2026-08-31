#!/bin/bash
# ah4c.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$6"
hostDir="${57}"
cdvrStartingChannel="${58}"
cdvrM3UName="${59}"
cdvrM3UNameNoExt="${cdvrM3UName%.m3u}"
ah4cContainer=$(emptyIfHash "${60}")

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort" "$extension$ah4cContainer"
# one-clickCdvrNumbering <CDVR starting-channel arg; "#" if unset>
one-clickCdvrNumbering "$cdvrStartingChannel"

envVars=(
"TAG=$2"
"CONTAINER_NAME=$extension$ah4cContainer"
"HOSTNAME=$extension$ah4cContainer"
"DOMAIN=$3"
"DOCKER_RUNTIME=$4"
"GPU_DEVICE=$5"
"HOST_PORT=$6"
"IPADDRESS=$7"
"NUMBER_TUNERS=$8"
"TUNER1_IP=$9"
"ENCODER1_URL=${10}"
"TUNER2_IP=${11}"
"ENCODER2_URL=${12}"
"TUNER3_IP=${13}"
"ENCODER3_URL=${14}"
"TUNER4_IP=${15}"
"ENCODER4_URL=${16}"
"TUNER5_IP=${17}"
"ENCODER5_URL=${18}"
"TUNER6_IP=${19}"
"ENCODER6_URL=${20}"
"TUNER7_IP=${21}"
"ENCODER7_URL=${22}"
"TUNER8_IP=${23}"
"ENCODER8_URL=${24}"
"TUNER9_IP=${25}"
"ENCODER9_URL=${26}"
"STREAMER_APP=${27}"
"PYATV=${28}"
"CHANNELSIP=${29}"
"ALERT_SMTP_SERVER=${30}"
"ALERT_AUTH_SERVER=${31}"
"ALERT_EMAIL_FROM=${32}"
"ALERT_EMAIL_PASS=${33}"
"ALERT_EMAIL_TO=${34}"
"ALERT_WEBHOOK_URL=${35}"
"LIVETV_ATTEMPTS=${36}"
"CREATE_M3US=${37}"
"UPDATE_SCRIPTS=${38}"
"UPDATE_M3US=${39}"
"TZ=${40}"
"SPEED_MODE=${41}"
"KEEP_WATCHING=${42}"
"AUTOCROP_CHANNELS=${43}"
"LINKPI_HOSTNAME=${44}"
"LINKPI_USERNAME=${45}"
"LINKPI_PASSWORD=${46}"
"USER_SCRIPT=${47}"
"NULL_FRAME_INSERTION=${48}"
"PLAYBACK_DETECTION=${49}"
"PLAYBACK_STATIC_TIMEOUT=${50}"
"PLAYBACK_DELAY=${51}"
"PREROLL_FILE=${52}"
"ENCODER_CODEC=${53}"
"HEARTBEAT_INTERVAL=${54}"
"NVIDIA_VISIBLE_DEVICES=${55}"
"NVIDIA_DRIVER_CAPABILITIES=${56}"
"HOST_DIR=${57}"
"CDVR_STARTING_CHANNEL=${58}"
"CDVR_M3U_NAME=${59}"
"AH4C_CONTAINER=${60}"
)

synologyDirs=(
"$hostDir/ah4c$ah4cContainer/scripts"
"$hostDir/ah4c$ah4cContainer/m3u"
"$hostDir/ah4c$ah4cContainer/adb"
)

# one-clickCreateStack -- no args; uses the envVars[] and synologyDirs[] arrays above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp "http://$extensionURL" "$extension$ah4cContainer"

# one-clickVerifyM3U <m3u URL to poll for #EXTM3U> [extra failure-hint line]...
one-clickVerifyM3U "http://$extensionURL/m3u/$cdvrM3UName" \
  "Confirm $hostDir/ah4c$ah4cContainer/m3u/$cdvrM3UName exists and matches CDVR_M3U_NAME."

# one-clickRegisterSource <CDVR source slug> <channel JSON>
# one-clickChannelJson name=.. url=.. [type=HLS] [source=URL] [text=..] [limit=..] [xmltv=..] [start=..]
one-clickRegisterSource "ah4c$ah4cContainer-$cdvrM3UNameNoExt" \
  "$(one-clickChannelJson name="ah4c$ah4cContainer - $cdvrM3UNameNoExt" type=MPEG-TS \
     url="http://$extensionURL/m3u/$cdvrM3UName")"
