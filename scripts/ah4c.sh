#!/bin/bash
# ah4c.sh
# 2026.09.16

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$6"
hostDir="${58}"
cdvrStartingChannel="${59}"
cdvrM3UName="${60}"
cdvrM3UNameNoExt="${cdvrM3UName%.m3u}"
ah4cContainer=$(emptyIfHash "${61}")

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
"FASTCHANNELS_URL=${30}"
"ALERT_SMTP_SERVER=${31}"
"ALERT_AUTH_SERVER=${32}"
"ALERT_EMAIL_FROM=${33}"
"ALERT_EMAIL_PASS=${34}"
"ALERT_EMAIL_TO=${35}"
"ALERT_WEBHOOK_URL=${36}"
"LIVETV_ATTEMPTS=${37}"
"CREATE_M3US=${38}"
"UPDATE_SCRIPTS=${39}"
"UPDATE_M3US=${40}"
"TZ=${41}"
"SPEED_MODE=${42}"
"KEEP_WATCHING=${43}"
"AUTOCROP_CHANNELS=${44}"
"LINKPI_HOSTNAME=${45}"
"LINKPI_USERNAME=${46}"
"LINKPI_PASSWORD=${47}"
"USER_SCRIPT=${48}"
"NULL_FRAME_INSERTION=${49}"
"PLAYBACK_DETECTION=${50}"
"PLAYBACK_STATIC_TIMEOUT=${51}"
"PLAYBACK_DELAY=${52}"
"PREROLL_FILE=${53}"
"ENCODER_CODEC=${54}"
"HEARTBEAT_INTERVAL=${55}"
"NVIDIA_VISIBLE_DEVICES=${56}"
"NVIDIA_DRIVER_CAPABILITIES=${57}"
"HOST_DIR=${58}"
"CDVR_STARTING_CHANNEL=${59}"
"CDVR_M3U_NAME=${60}"
"AH4C_CONTAINER=${61}"
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
