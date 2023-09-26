#! /bin/bash
#listcomskipignore.sh for olivetin-for-channels

curl http://$CHANNELS_DVR/settings \
  | jq 'to_entries | map(select(.key | test("comskip.ignore.channel.\\d+"))) | from_entries'