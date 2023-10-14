#!/bin/bash

set -x

numberLines=$1
filterResult=$(echo $2 | sed 's/[][\.*^$(){}?+|/]/\\&/g')

if [[ "$filterResult" == "none" ]]; then
  curl http://$CHANNELS_DVR/log?n=$numberLines
else
  curl http://$CHANNELS_DVR/log?n=$numberLines | grep "$filterResult"
  runResult=$?
  [[ "$runResult" == "1" ]] && echo "No results found using filter of $filterResult" && exit 0
  [[ "$runResult" == "0" ]] && exit 0
fi