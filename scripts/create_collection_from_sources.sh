#!/bin/bash

set -x

dvr=$1
collectionName="$2"
sourceNames=("${@:3}")

channelsHost=$(echo $dvr | awk -F: '{print $1}')
channelsPort=$(echo $dvr | awk -F: '{print $2}')

python3 /config/create_collection_from_sources.py -i $channelsHost -p $channelsPort -n $collectionName "${sourceNames[@]}"
