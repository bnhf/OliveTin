#! /bin/bash

dvr=$1

curl http://$dvr/settings \
  | jq 'to_entries | map(select(.key | test("comskip.ignore.channel.\\d+"))) | from_entries'