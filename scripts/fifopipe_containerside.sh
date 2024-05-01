#!/bin/bash

set -x

hostCommand="$1"
hostCommandArguments="$2"

fifoPipe=/config/fifopipe

[ ! -p $fifoPipe ] \
  && echo "FIFO pipe not found. Is the host helper script running?" \
  && echo -e "Run sudo -E ./fifopipe_hostside.sh \"\$PATH\" from the directory you have bound to /config on your host computer" \
  && exit 1

echo "$hostCommand" "$hostCommandArguments" > $fifoPipe
sleep 1
cat "$fifoPipe"_latest.log
