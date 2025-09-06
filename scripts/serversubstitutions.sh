#!/bin/bash
# serversubstitutions.sh
# 2025.09.04

set -x

substituteDropdown() {
  sed -i '/- name: dvr/,/dvr default/c\      - name: dvr\n        description: Channels DVR server to use.\n        choices:\n          - title: '"$CHANNELS_DVR"'\n            value: '"$CHANNELS_DVR"'\n          #lastchoice\n        default: '"$CHANNELS_DVR"' #dvr default' /config/config.yaml

  dvrs=($CHANNELS_DVR_ALTERNATES)
  for dvr in "${dvrs[@]}"; do
    sed -i 's/#lastchoice/- title: '"$dvr"'\n            value: '"$dvr"'\n          #lastchoice/g' /config/config.yaml
  done
}

channelsDvrServers() {
  if sed '/default: .* dvr default/s/default: .* #/default: '"$CHANNELS_DVR"' #/g' /config/config.yaml \
    | cmp -s - /config/config.yaml; then
    echo "No substitutions"
  else
    echo "Substitutions made"
    sed -n '/default: .* dvr default/s/default: .* #/default: '"$CHANNELS_DVR"' #/p' /config/config.yaml
    sed '/default: .* dvr default/s/default: .* #/default: '"$CHANNELS_DVR"' #/g' /config/config.yaml > /tmp/config.yaml \
    && mv /tmp/config.yaml /config/config.yaml
  fi

  [[ -n $CHANNELS_DVR_ALTERNATES ]] \
  && substituteDropdown || true
}

main() {
  channelsDvrServers
}

main
