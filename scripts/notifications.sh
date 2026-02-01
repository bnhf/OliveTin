#!/bin/bash
# notifications.sh
# 2026.01.18

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

messageTitle=\"$1\"
messageContent=\"$2\"
#messageRepeats=$(($3 / 5))
messageTimeout="$3"

clients=($CHANNELS_CLIENTS)

#for ((i = 1; i <= $messageRepeats; i++)); do
  for client in "${clients[@]}"; do
    echo "Sending $messageTitle:$messageContent to $client"
    #curl -v --header "Content-Type: application/json" http://$client:57000/api/notify -d '{"title": '"$messageTitle"', "message": '"$messageContent"'}'
    curl -s -v --header "Content-Type: application/json" http://$client:57000/api/notify -d '{"title": '"$messageTitle"', "message": '"$messageContent"', "timeout": '"$messageTimeout"'}'
    echo -e "\n"
  done
  #sleep 5
#done
