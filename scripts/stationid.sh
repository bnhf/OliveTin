#! /bin/bash
#stationid.sh for olivetin-for-channels

stationName=$(echo "$1" | sed 's/ /%20/g; s/^/%22/; s/$/%22/')

curl http://$CHANNELS_DVR/tms/stations/$stationName \
  | jq --raw-output "sort_by(.type, .name) | .[] | \"type: \(.type), name: \(.name), callSign: \(.callSign), stationId: \(.stationId), affiliate: \(.affiliateCallSign), logo: \(.preferredImage.uri)\""