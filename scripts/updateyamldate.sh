#!/bin/bash

set -x

currentDate=$(date +%Y.%m.%d)

sed -i 's/pageTitle: OliveTin-for-Channels 1970.01.01/pageTitle: OliveTin-for-Channels '"$currentDate"'/' /tmp/config.yaml
