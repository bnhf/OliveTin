#! /bin/bash

checkYamls() {

  #local scripts=($@)
  local yamls=($(cd /tmp && ls *.yaml))
  
  for yaml in "${yamls[@]}"
    do
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

  #local scripts=($@)
  local scripts=($(cd /tmp && ls *.sh *.rb *.py))
  
  for script in "${scripts[@]}"
    do
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

loadScriptArguments() {
  local argumentFiles=($(cd /config && ls *.running))
  [[ -z $argumentFiles ]] && return 0

  for argumentFile in "${argumentFiles[@]}"
    do
      arguments=$(cat /config/$argumentFile)
      grep -q '.sh' /config/$argumentFile
      standaloneScript=$?
      [[ "$standaloneScript" == "0" ]] && /config/$arguments \
      && echo "Launching script with these arguments: $arguments"
      [[ "$standaloneScript" == "1" ]] && /config/foreground.sh $arguments \
      && echo "Launching foreground.sh with these arguments: $arguments"
  done
}

# channelsDvrServers() {
#   for dvrServer in $(printenv | cut -d= -f1); do
#     if [[ $dvrServer == CHANNELS_DVR* && -n "${!dvrServer}" ]]; then
#       dvrServers+=("$dvrServer=${!dvrServer}")
#     fi
#   done

#   for dvrServer in "${dvrServers[@]}"; do
#     serverPort=$(awk -F= '{print $2}')
#     grep $dvrServer | sed -i 's/'"$dvrServer"'/'"$serverPort"'/g' /config/config.yaml
#   done
# }

main() {
  cd ~
  checkYamls  
  checkScripts
  loadScriptArguments
  /usr/bin/OliveTin
}

main