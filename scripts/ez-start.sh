#!/bin/bash
# ez-start.sh
# 2026.05.05

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x

ez-start() {
  /config/portainer.sh "$PORTAINER_PASSWORD" "9000" "9443"
  /config/olivetin.sh "latest" "$DOMAIN" "${HOST_PORT:-1337}" "${CHANNELS_DVR%%:*}" "${CHANNELS_DVR#*:}" "$CHANNELS_DVR_ALTERNATES" "$CHANNELS_CLIENTS" "$ALERT_SMTP_SERVER" "$ALERT_EMAIL_FROM" "$ALERT_EMAIL_PASS" "$ALERT_EMAIL_TO" "true" "true" "$TZ" "${HOST_DIR:-/data}" "$DVR_SHARE" "$LOGS_SHARE" "${TUBEARCHIVIST_SHARE}" "$DVR2_SHARE" "$LOGS2_SHARE" "${TUBEARCHIVIST2_SHARE}" "$DVR3_SHARE" "$LOGS3_SHARE" "${TUBEARCHIVIST3_SHARE}" "${HOST_SFS_PORT:-8080}" "${FOLDER:-/web}" "${PORTAINER_TOKEN}" "${PORTAINER_HOST:-$CHANNELS_DVR_HOST}" "${PORTAINER_PORT:-9443}" "${PORTAINER_ENV:-1}" "${PERSISTENT_LOGS:-false}"
  /config/olivetin-for-channels.sh "true" "" "" "" "" "" "false" "false" "false" "false" "false" "false" "false" "false" "false"
}

main() {
  [[ -n $EZ_START && -n $PORTAINER_PASSWORD ]] && ez-start || echo "EZ_START and PORTAINER_PASSWORD not set, skipping ez-start.sh"
}

main
