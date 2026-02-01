#!/bin/bash
# create_collection_from_sources.sh
# 2025.12.22

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

dvr=$1
collectionName="$2"
sourceNames=("${@:3}")

channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')

python3 /config/create_collection_from_sources.py -i $channelsHost -p $channelsPort -n "$collectionName" "${sourceNames[@]}"
