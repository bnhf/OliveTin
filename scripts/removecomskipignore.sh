#! /bin/bash
#removecomskipignore.sh for olivetin-for-channels

channel=$1

curl -XDELETE http://$CHANNELS_DVR/comskip/ignore/channel/$channel