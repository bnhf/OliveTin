#!/bin/bash

set -x

dvr=$1
numberLines=$2
filterResult=$(echo $3 | sed 's/[][\.*^$(){}?+|/]/\\&/g')

if [[ "$filterResult" == "none" ]]; then
  curl http://$dvr/log?n=$numberLines
else
  curl http://$dvr/log?n=$numberLines | grep "$filterResult"
  runResult=$?
  [[ "$runResult" == "1" ]] && echo "No results found using filter of $filterResult" && exit 0
  [[ "$runResult" == "0" ]] && exit 0
fi