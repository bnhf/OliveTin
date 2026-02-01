#!/bin/bash
# listrunningcontainers.sh
# 2026.01.26

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

listRunningContainers() {
  imagesPlusPorts=(
    "adbtuner:5592"
    "ah4c:7654"
    "channels-remote-plus:5000"
    "eplustv:8000"
    "espn4cc4c:8094"
    "filebot:5800"
    "frndlytv-for-channels:80"
    "fruitdeeplinks:6655"
    "mediainfo:5800"
    "mlbserver:9999"
    "olivetin:1337"
    "organizr:80"
    "plex-for-channels:7777"
    "pluto-for-channels:7777"
    "portainer-ce:9000"
    "prismcast:5589"
    "roku-ecp-tuner:5000"
    "samsung-tvplus-for-channels:80"
    "stream-link-manager-for-channels:5000"
    "tubi-for-channels:7777"
    "tv-logo-manager:8084"
    "vlc-bridge-fubo:7777"
    "vlc-bridge-pbs:7777"
    "vlc-bridge-uk:7777"
  )

  dockerPs="$(docker ps --format "{{.Image}}\t{{.Ports}}")"

  for imagePlusPort in "${imagesPlusPorts[@]}"; do
    containerPort="${imagePlusPort##*:}"
    imageName="${imagePlusPort%%:*}"
    imageNameUnderbars="${imageName//-/_}"
    imageNameUnderbarsCaps="${imageNameUnderbars^^}"

    hostPort="$(
      printf '%s\n' "$dockerPs" \
        | grep -F "$imageName" \
        | head -n1 \
        | awk -F"->${containerPort}/" '{print $1}' \
        | awk -F: '{print $NF}'
    )"

    [[ -n "$hostPort" ]] \
      && runningContainers+="${imageName} "
  done

  printf '%s\n' "${runningContainers[@]}"
}

listRunningContainers
