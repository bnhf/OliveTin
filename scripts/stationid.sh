#! /bin/bash

dvr=$1
stationName=$(echo "$2" | sed 's/ /%20/g; s/^/%22/; s/$/%22/')

curl http://$dvr/tms/stations/$stationName \
  | jq --raw-output "sort_by(.type, .name) | .[] | \"type: \(.type), name: \(.name), callSign: \(.callSign), stationId: \(.stationId), affiliate: \(.affiliateCallSign), logo: \(.preferredImage.uri)\""