#! /bin/bash
#setcomskipignore.sh for olivetin-for-channels

channel=$1

curl -XPUT http://$CHANNELS_DVR/comskip/ignore/channel/$channel