#!/bin/bash
# watchtower.sh
# 2026.08.29

source /config/one-click.sh || { echo "one-click.sh not found in /config"; exit 1; }

envVars=(
"TAG=$1"
"WATCHTOWER_RUN_ONCE=$2"
)

# one-clickCreateStack -- no args; uses the envVars[] array above
one-clickCreateStack
