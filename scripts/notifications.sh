#!/bin/bash

#set -x

messageTitle=\"$1\"
messageContent=\"$2\"
messageRepeats=$(($3 / 5))
#messageTimeout=\"$3\"

clients=($CHANNELS_CLIENTS)

for ((i = 1; i <= $messageRepeats; i++)); do
  for client in "${clients[@]}"; do
    echo "Sending $messageTitle:$messageContent to $client"
    curl -v --header "Content-Type: application/json" http://$client:57000/api/notify -d '{"title": '"$messageTitle"', "message": '"$messageContent"'}'
    echo -e "\n"
  done
  sleep 5
done