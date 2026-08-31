#!/bin/bash
# espn4cc4c.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

dvr="$1"
hostPort="$4"
# each output has its own start channel ("#" = unset) and its own enable flag ("false" = off)
cc4cStartingChannel=$(emptyIfHash "${15}"); [[ -n $cc4cStartingChannel ]] && cc4cIgnoreM3UNumbers=ignore
ch4cStartingChannel=$(emptyIfHash "${17}"); [[ -n $ch4cStartingChannel ]] && ch4cIgnoreM3UNumbers=ignore
[[ "${14}" == "false" ]] && cc4cSource="" || cc4cSource="${14}"
[[ "${16}" == "false" ]] && ch4cSource="" || ch4cSource="${16}"

# one-clickPreflight <HOST_PORT arg> [label for status messages]
one-clickPreflight "$hostPort"

envVars=(
"TAG=$2"
"DOMAIN=$3"
"HOST_PORT=$4"
"TZ=$5"
"VC_RESOLVER_BASE_URL=$6"
"CC_HOST=$7"
"CC_PORT=$8"
"CH4C_HOST=$9"
"CH4C_PORT=${10}"
"LANES=${11}"
"FILTER_EXCLUDE_REAIR=${12}"
"HOST_DIR=${13}"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack

# one-clickWaitForUp [url=http://$extensionURL] [label] [maxTries=60; 0=forever]
one-clickWaitForUp

# one-clickRegisterSource <slug> <channel JSON> -- each output registered only if its source flag is set
[[ -n $cc4cSource ]] && one-clickRegisterSource ESPN4cc4c \
  "$(one-clickChannelJson name=ESPN4cc4c type=MPEG-TS numbering="$cc4cIgnoreM3UNumbers" start="$cc4cStartingChannel" \
     url="http://$extensionURL/out/playlist.m3u" \
     xmltv="http://$extensionURL/out/epg.xml")" || true

[[ -n $ch4cSource ]] && one-clickRegisterSource ESPN4ch4c \
  "$(one-clickChannelJson name=ESPN4ch4c type=MPEG-TS numbering="$ch4cIgnoreM3UNumbers" start="$ch4cStartingChannel" \
     url="http://$extensionURL/out/playlist.ch4c.m3u" \
     xmltv="http://$extensionURL/out/epg.xml")" || true
