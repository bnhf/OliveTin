#!/bin/bash
# listrunningprojects.sh
# 2026.01.26

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
greenIcon=\"custom-webui\/icons\/channels.png\"
purpleIcon=\"https:\/\/community-assets.getchannels.com\/original/2X/5/55232547f7e8f243069080b6aec0c71872f0f537.png\"
configFile=/config/config.yaml
configTemp=/tmp/config.yaml
updateIconGreen() { sed -i "/#${stackName} icon/s|img src = .* width|img src = $greenIcon width|" "$configTemp"; }
updateIconPurple() { sed -i "/#${stackName} icon/s|img src = .* width|img src = $purpleIcon width|" "$configTemp"; }

substituteIcons() {
  cp $configFile /tmp

  imagesPlusStacks=(
    "adbtuner:adbtuner"
    "ah4c:ah4c"
    "eplustv:eplustv"
    "espn4cc4c:espn4cc4c"
    "frndlytv-for-channels:frndlytv-for-channels"
    "filebot:filebot"
    "fruitdeeplinks:fruitdeeplinks"
    "mediainfo:mediainfo"
    "mlbserver:mlbserver"
    "multi4channels:multi4channels"
    "multichannelview:multichannelview"
    "olivetin:olivetin-for-channels"
    "plex-for-channels:plex-for-channels"
    "pluto-for-channels:pluto-for-channels"
    "portainer-ce:portainer"
    "prismcast:prismcast"
    "channels-remote-plus:channels-app-remote-plus"
    "roku-ecp-tuner:roku-tuner-bridge"
    "samsung-tvplus-for-channels:samsung-tvplus-for-channels"
    "stream-link-manager-for-channels:slm"
    "tubi-for-channels:tubi-for-channels"
    "tv-logo-manager:tv-logo-manager"
    "vlc-bridge-fubo:vlc-bridge-fubo"
    "vlc-bridge-pbs:vlc-bridge-pbs"
    "vlc-bridge-uk:vlc-bridge-uk"
  )

  dockerPs="$(docker ps --format "{{.Image}}\t{{.Ports}}")"

  for imagePlusStack in "${imagesPlusStacks[@]}"; do
    stackName="${imagePlusStack##*:}"
    imageName="${imagePlusStack%%:*}"

    runningContainer="$(
      printf '%s\n' "$dockerPs" \
        | grep -F "$imageName" \
        | head -n1 \
        | awk -F: '{print $1}' \
        | awk -F/ '{print $NF}'
    )"

    [[ -n $runningContainer ]] && updateIconGreen || updateIconPurple
  done

  cp $configTemp /config
}

substituteIcons
