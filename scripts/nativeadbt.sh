#!/bin/bash
# nativeadbt.sh
# 2026.04.22

script=$(basename "$0" | sed 's/\.sh$//')
exec 3> /config/$script.debug.log
BASH_XTRACEFD=3
set -x
shopt -s extglob

dvr="$1"
adbtunerSource="$2:$3"
nativeProviderName="$4"
nativeRemove="$5"
[[ "$6" == "#" ]] && adbtStartingChannel="" || adbtStartingChannel="$6"
[[ -n $adbtStartingChannel ]] && adbtIgnoreM3UNumbers="ignore" || adbtIgnoreM3UNumbers=""

NATIVE_JSON_URL="https://raw.githubusercontent.com/babsonnexus/adbtuner_native/main/adbtuner_export_formatted.json"
NATIVE_ZIP_URL="https://raw.githubusercontent.com/babsonnexus/adbtuner_native/main/user_configurations.zip"

curl -s -o /dev/null http://$adbtunerSource || { echo "ADBTuner not answering on http://$adbtunerSource"; exit 1; }

deleteExistingNative() {
  echo -e "[INFO] Deleting existing channels for provider: $nativeRemove..."
  curl -fsS "http://$adbtunerSource/api/v1/channels" -H 'accept: application/json' \
  | jq -r --arg provider "$nativeRemove" '.[] | select(.provider_name == $provider) | .id' \
  | while read -r adbtunerChannel; do
      [[ -z "$adbtunerChannel" ]] && continue
      nativeChannel="http://$adbtunerSource/api/v1/channels/$adbtunerChannel"
      echo -e "\nDELETE $nativeRemove $nativeChannel"
      curl -sS -X DELETE "$nativeChannel"
    done
  echo -e "\n[INFO] Deletion of existing channels for provider: $nativeRemove completed."
}

installNativeConfigs() {
  local uuids="$1"
  local zipFile="/tmp/native_user_configurations.zip"
  local extractDir="/tmp/native_user_configurations"
  local configsURL="http://${adbtunerSource}/api/v1/configurations"
  local configURL="http://${adbtunerSource}/api/v1/configuration"

  echo -e "\n[INFO] Downloading user_configurations.zip..."
  curl -fsS -o "$zipFile" "$NATIVE_ZIP_URL" || { echo "[ERROR] Failed to download user_configurations.zip"; return 1; }

  rm -rf "$extractDir"
  mkdir -p "$extractDir"
  unzip -q "$zipFile" -d "$extractDir" || { echo "[ERROR] Failed to unzip user_configurations.zip"; return 1; }

  local allConfigs
  if ! allConfigs=$(curl -sS -X GET "${configsURL}" -H 'accept: application/json'); then
    echo "[ERROR] Failed to fetch configurations from ${configsURL}"
    rm -rf "$extractDir" "$zipFile"
    return 1
  fi

  while read -r uuid; do
    [[ -z "$uuid" ]] && continue

    echo "[INFO] Checking for configuration ${uuid} at ${configsURL}"

    local configFile
    configFile=$(find "$extractDir" -name "${uuid}.json" -type f 2>/dev/null | head -1)

    if [[ -z "$configFile" ]]; then
      echo "[WARN] No configuration file found for UUID: ${uuid} — skipping."
      continue
    fi

    if echo "${allConfigs}" | jq -e --arg uuid "${uuid}" '
        (map(select(
          (.uuid == $uuid) or
          (.json_data.uuid == $uuid)
        )) | length) > 0
      ' >/dev/null 2>&1; then
      echo "[INFO] Configuration ${uuid} already exists. Skipping."
      continue
    fi

    local configContent
    configContent=$(cat "$configFile" | jq 'walk(if type == "string" then gsub("monkey (?=-p)"; "monkey --pct-syskeys 0 ") else . end)')

    echo "[INFO] Posting configuration ${uuid}..."
    local postHttpReturnCode
    postHttpReturnCode=$(curl -sS -o /tmp/native_config_post_response.json -w '%{http_code}' \
      -X POST "${configURL}" \
      -H 'accept: application/json' \
      -H 'Content-Type: application/json' \
      -d "{\"json_data\": ${configContent}}")

    if [[ "${postHttpReturnCode}" =~ ^2 ]]; then
      echo "[INFO] Configuration ${uuid} created successfully (HTTP ${postHttpReturnCode})."
    else
      echo "[ERROR] Failed to create configuration ${uuid} (HTTP ${postHttpReturnCode}). Response:"
      cat /tmp/native_config_post_response.json
      echo
    fi
  done <<< "$uuids"

  rm -rf "$extractDir" "$zipFile"
  echo "[INFO] Configuration installation completed."
}

createNativeChannels() {
  local nativeJSON
  echo -e "\n[INFO] Fetching native channel data from GitHub..."
  if ! nativeJSON=$(curl -fsS "$NATIVE_JSON_URL"); then
    echo "[ERROR] Failed to fetch native channel JSON from GitHub"
    return 1
  fi

  local filteredRecords
  filteredRecords=$(echo "$nativeJSON" | jq -c --arg provider "$nativeProviderName" '[.[] | select(.provider_name == $provider)]')

  local count
  count=$(echo "$filteredRecords" | jq 'length')
  echo -e "[INFO] Found $count channel(s) for provider: $nativeProviderName"

  if [[ "$count" -eq 0 ]]; then
    echo "[WARN] No channels found for provider: $nativeProviderName"
    return 0
  fi

  local uniqueUUIDs
  uniqueUUIDs=$(echo "$filteredRecords" | jq -r '.[].configuration_uuid' | sort -u)
  installNativeConfigs "$uniqueUUIDs"

  echo -e "\n[INFO] Creating $count channel(s) for provider: $nativeProviderName"

  local firstNumber
  firstNumber=$(echo "$filteredRecords" | jq '.[0].number')

  while IFS= read -r record; do
    local name number url package_name alt_package tvc_guide guide_offset config_uuid m3u_id channelNumber
    name=$(echo "$record" | jq -r '.name')
    number=$(echo "$record" | jq -r '.number')
    url=$(echo "$record" | jq -r '.url')
    package_name=$(echo "$record" | jq -r '.package_name')
    alt_package=$(echo "$record" | jq -r '.alternate_package_name')
    [[ -z "$alt_package" && -n "${ALT_PACKAGE_OVERRIDES[$nativeProviderName]+x}" ]] && alt_package="${ALT_PACKAGE_OVERRIDES[$nativeProviderName]}"
    tvc_guide=$(echo "$record" | jq -r '.tvc_guide_stationid')
    guide_offset=$(echo "$record" | jq -r '.guide_offset_hours')
    config_uuid=$(echo "$record" | jq -r '.configuration_uuid')
    m3u_id="${nativeProviderName}_${number}"
    [[ -n $adbtStartingChannel ]] && channelNumber=$(( number - firstNumber + adbtStartingChannel )) || channelNumber=$number

    jq -n \
      --arg m3u_id "$m3u_id" \
      --arg provider "$nativeProviderName" \
      --argjson number "$channelNumber" \
      --arg name "$name" \
      --arg package "$package_name" \
      --arg alt_package "$alt_package" \
      --arg url "$url" \
      --arg config "$config_uuid" \
      --arg tvc "$tvc_guide" \
      --arg offset "$guide_offset" \
      '{
        m3u_id: $m3u_id,
        provider_name: $provider,
        number: $number,
        name: $name,
        package_name: $package,
        alternate_package_name: $alt_package,
        url_or_identifier: $url,
        configuration_uuid: $config,
        tvc_guide_stationid: $tvc,
        guide_offset_hours: $offset,
        data: null,
        id: 0
      }' |
      curl -fsS "http://$adbtunerSource/api/v1/channels" \
        -H 'accept: application/json' \
        -H 'Content-Type: application/json' \
        -d @- \
      || { echo "POST failed for channel: $name" >&2; }

    echo "Created channel: $name"
  done < <(echo "$filteredRecords" | jq -c '.[]')

  echo -e "[INFO] Creation of $count channel(s) for provider: $nativeProviderName completed."
}

customChannels() {
cat <<EOF
{
  "name": "ADBTuner - ${nativeProviderName}",
  "type": "MPEG-TS",
  "source": "URL",
  "url": "http://$adbtunerSource/channels.m3u8?provider=${nativeProviderName}",
  "text": "",
  "refresh": "24",
  "limit": "",
  "satip": "",
  "numbering": "$adbtIgnoreM3UNumbers",
  "start_number": "$adbtStartingChannel",
  "logos": "",
  "xmltv_url": "",
  "xmltv_refresh": "3600"
}
EOF
}

cdvrCustomSource() {
  echo -e "\n[INFO] Updating Custom Source in CDVR for ADBTuner provider: $nativeProviderName..."
  customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

  echo -e "JSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" "http://$dvr/providers/m3u/sources/ADBTuner-${nativeProviderName// /}"
  echo -e "\n[INFO] CDVR Custom Source update completed for ADBTuner provider: $nativeProviderName"
}

ALL_PROVIDERS=(app_nbc app_cbs app_foxone app_pbs app_espn app_nfl app_hgtv app_cnn app_tbs app_tnt app_trutv app_ae app_history app_amc)

declare -A ALT_PACKAGE_OVERRIDES
ALT_PACKAGE_OVERRIDES=(
  [app_nbc]="com.onemainstream.nbcunivers.android"
  [app_espn]="com.espn.gtv"
  [app_amc]="com.amctve.amcfiretv"
  [app_cnn]="com.cnn.mobile.fire.tv"
)

main() {
  if [[ "$nativeProviderName" == "ALL" ]]; then
    local originalRemove="$nativeRemove"
    for provider in "${ALL_PROVIDERS[@]}"; do
      nativeProviderName="$provider"
      [[ "$originalRemove" == "ALL" ]] && nativeRemove="$provider" || nativeRemove="$originalRemove"
      [[ "$nativeRemove" != "none" ]] && deleteExistingNative && echo
      createNativeChannels
      cdvrCustomSource
    done
  else
    [[ "$nativeProviderName" == "remove_only" && "$nativeRemove" != "none" ]] && deleteExistingNative && exit 0
    [[ "$nativeRemove" != "none" ]] && deleteExistingNative && echo
    createNativeChannels
    cdvrCustomSource
  fi
}

main
