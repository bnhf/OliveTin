#!/bin/bash
# dockercompose.sh
# 2026.01.18

dockerCompose=$1

cat /config/$dockerCompose.yaml
[ -f /config/$dockerCompose.env ] || exit 0 && cat /config/$dockerCompose.env 1>&2
