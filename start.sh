#! /bin/bash

checkYamls() {
  local yamls=($(cd /tmp && ls *.yaml *.env))
  
  for yaml in "${yamls[@]}"; do
    if [ ! -f /config/$yaml ] && [ -f /tmp/$yaml ] || [[ $UPDATE_YAMLS == "true" ]]; then
      cp /tmp/$yaml /config 2>/dev/null \
      && echo "No existing /config/$yaml found or UPDATE_YAMLS set to true"
    else
      if [ -f /tmp/$yaml ]; then
        echo "Existing /config/$yaml found, and will be preserved"
      fi
    fi
  done
}

checkScripts() {
  local scripts=($(cd /tmp && ls *.sh *.rb *.py))
  
  for script in "${scripts[@]}"; do
    if [ ! -f /config/$script ] && [ -f /tmp/$script ] || [[ $UPDATE_SCRIPTS == "true" ]]; then
      cp /tmp/$script /config 2>/dev/null \
      && chmod +x /config/$script \
      && echo "No existing /config/$script found or UPDATE_SCRIPTS set to true"
    else
      if [ -f /tmp/$script ]; then
        echo "Existing /config/$script found, and will be preserved"
      fi
    fi
  done
}

killZombies() {
  echo "----------------------------------------"
  echo "Checking for .running files that don't match with currently defined DVRs..."
  dvrs=($CHANNELS_DVR $CHANNELS_DVR_ALTERNATES)
  grepArguments=""

  for dvr in "${dvrs[@]}"; do
    channelsHost=$(echo $dvr | awk -F: '{print $1}')
    channelsPort=$(echo $dvr | awk -F: '{print $2}')
    grepArguments="$grepArguments -e $channelsHost-$channelsPort"
  done

  find /config -type f -name '*.running' | grep -v $grepArguments | xargs rm -fv
}

loadScriptArguments() {
  local argumentFiles=($(cd /config && ls *.running))
  [[ -z $argumentFiles ]] && return 0

  for argumentFile in "${argumentFiles[@]}"; do
    arguments=$(cat /config/$argumentFile)
    grep -q '.sh' /config/$argumentFile
    standaloneScript=$?
    [[ "$standaloneScript" == "0" ]] \
      && echo "----------------------------------------" \
      && echo "Launching script with these arguments: $arguments" \
      && /config/$arguments
    [[ "$standaloneScript" == "1" ]] \
      && echo "----------------------------------------" \
      && echo "Launching foreground.sh with these arguments: $arguments" \
      && /config/foreground.sh $arguments true
  done
}

substituteDropdown() {
  sed -i '/- name: dvr/,/dvr default/c\      - name: dvr\n        description: Channels DVR server to use.\n        choices:\n          - title: '"$CHANNELS_DVR"'\n            value: '"$CHANNELS_DVR"'\n          #lastchoice dvr default' /config/config.yaml

  dvrs=($CHANNELS_DVR_ALTERNATES)
  for dvr in "${dvrs[@]}"; do
    sed -i 's/#lastchoice dvr default/- title: '"$dvr"'\n            value: '"$dvr"'\n          #lastchoice dvr default/g' /config/config.yaml
  done
}

channelsDvrServers() {
  sed -i '/default: .* dvr default/s/default: .* #/default: '"$CHANNELS_DVR"' #/g' /config/config.yaml
  [[ -n $CHANNELS_DVR_ALTERNATES ]] \
  && substituteDropdown
}

main() {
  cd ~
  checkYamls  
  checkScripts
  killZombies
  loadScriptArguments
  channelsDvrServers
  mkdir -p /var/www/olivetin/icons && cp /tmp/*.png /var/www/olivetin/icons
  /usr/bin/OliveTin
}

main