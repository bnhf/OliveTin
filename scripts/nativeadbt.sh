#!/bin/bash
# nativeadbt.sh
# 2026.07.30

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

NATIVE_JSON_URL="https://raw.githubusercontent.com/babsonnexus/hdmi-encoder-native-apps/main/adbtuner_native/stations/0000_app_all_stations.json"
NATIVE_REPO_URL="https://github.com/babsonnexus/hdmi-encoder-native-apps"

curl -s -o /dev/null http://$adbtunerSource || { echo "ADBTuner not answering on http://$adbtunerSource"; exit 1; }

deleteExistingNative() {
  local filterDesc="$nativeRemove"
  local jqSelect
  if [[ "$nativeRemove" == "ALL" ]]; then
    jqSelect='(.provider_name == "native") or (.provider_name | startswith("app_"))'
    filterDesc="native + app_* (ALL)"
  else
    jqSelect='.provider_name == $provider'
  fi

  echo -e "[INFO] Deleting existing channels for provider: $filterDesc..."
  curl -fsS "http://$adbtunerSource/api/v1/channels" -H 'accept: application/json' \
  | jq -r --arg provider "$nativeRemove" ".[] | select($jqSelect) | .id" \
  | while read -r adbtunerChannel; do
      [[ -z "$adbtunerChannel" ]] && continue
      nativeChannel="http://$adbtunerSource/api/v1/channels/$adbtunerChannel"
      echo -e "\nDELETE $filterDesc $nativeChannel"
      curl -sS -X DELETE "$nativeChannel"
    done
  echo -e "\n[INFO] Deletion of existing channels for provider: $filterDesc completed."
}

registerNativeRepo() {
  local reposURL="http://${adbtunerSource}/api/v1/repositories"

  echo -e "\n[INFO] Checking if native repo is already registered..."
  local existing
  if ! existing=$(curl -sS -X GET "${reposURL}" -H 'accept: application/json'); then
    echo "[ERROR] Failed to fetch repositories from ${reposURL}"
    return 1
  fi

  local repoDir
  repoDir=$(echo "$NATIVE_REPO_URL" | sed 's|https://||' | tr '/' '-')

  if echo "${existing}" | jq -e --arg dir "$repoDir" 'any(.[]; .directory == $dir)' >/dev/null 2>&1; then
    echo "[INFO] Native repo already registered. Skipping."
    return 0
  fi

  echo "[INFO] Registering native repo: ${NATIVE_REPO_URL}..."
  local httpCode
  httpCode=$(curl -sS -o /tmp/native_repo_post_response.json -w '%{http_code}' \
    -X POST "${reposURL}" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{\"url\": \"${NATIVE_REPO_URL}\"}")

  if [[ "${httpCode}" =~ ^2 ]]; then
    echo "[INFO] Native repo registered successfully (HTTP ${httpCode})."
  else
    echo "[ERROR] Failed to register native repo (HTTP ${httpCode}). Response:"
    cat /tmp/native_repo_post_response.json
    echo
    return 1
  fi
}

createNativeChannels() {
  local nativeJSON="$1"

  if [[ -z "$nativeJSON" ]]; then
    echo -e "\n[INFO] Fetching native channel data from GitHub..."
    if ! nativeJSON=$(curl -fsS "$NATIVE_JSON_URL"); then
      echo "[ERROR] Failed to fetch native channel JSON from GitHub"
      return 1
    fi
  fi

  local filteredRecords
  if [[ "$nativeProviderName" == "native" ]]; then
    filteredRecords=$(echo "$nativeJSON" | jq -c '[.[]]')
  else
    filteredRecords=$(echo "$nativeJSON" | jq -c --arg provider "$nativeProviderName" '[.[] | select(.provider_name == $provider)]')
  fi

  local count
  count=$(echo "$filteredRecords" | jq 'length')
  echo -e "[INFO] Found $count channel(s) for provider: $nativeProviderName"

  if [[ "$count" -eq 0 ]]; then
    echo "[WARN] No channels found for provider: $nativeProviderName"
    return 0
  fi

  echo -e "\n[INFO] Creating $count channel(s) for provider: $nativeProviderName"

  local channelCounter
  [[ -n $adbtStartingChannel ]] && channelCounter=$adbtStartingChannel || channelCounter=""

  while IFS= read -r record; do
    local name number sort_order url package_name alt_package tvc_guide guide_offset config_uuid m3u_id channelNumber
    name=$(echo "$record" | jq -r '.name')
    number=$(echo "$record" | jq -r '.number')
    sort_order=$(echo "$record" | jq -r '.sort_order | tonumber | floor')
    url=$(echo "$record" | jq -r '.url')
    package_name=$(echo "$record" | jq -r '.package_name')
    alt_package=$(echo "$record" | jq -r '.alternate_package_name')
    local record_provider
    record_provider=$(echo "$record" | jq -r '.provider_name')
    [[ -z "$alt_package" && -n "${ALT_PACKAGE_OVERRIDES[$record_provider]+x}" ]] && alt_package="${ALT_PACKAGE_OVERRIDES[$record_provider]}"
    tvc_guide=$(echo "$record" | jq -r '.tvc_guide_stationid')
    guide_offset=$(echo "$record" | jq -r '.guide_offset_hours')
    config_uuid=$(echo "$record" | jq -r '.configuration_uuid')
    m3u_id="${nativeProviderName}_${number}"
    channelNumber=$channelCounter
    [[ -n $channelCounter ]] && (( channelCounter++ ))

    jq -n \
      --arg m3u_id "$m3u_id" \
      --arg provider "$nativeProviderName" \
      --arg number "$channelNumber" \
      --argjson sort_order "$sort_order" \
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
        number: (if $number == "" then "" else ($number | tonumber) end),
        sort_order: $sort_order,
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
  "numbering": "",
  "start_number": "",
  "logos": "",
  "xmltv_url": "",
  "xmltv_refresh": "3600"
}
EOF
}

cdvrCustomSource() {
  local sourceName="ADBTuner-${nativeProviderName// /}"
  local sourceURL="http://$dvr/providers/m3u/sources/$sourceName"

  echo -e "\n[INFO] Deleting existing Custom Source in CDVR for ADBTuner provider: $nativeProviderName..."
  curl -s -X DELETE "$sourceURL"

  echo -e "\n[INFO] Creating Custom Source in CDVR for ADBTuner provider: $nativeProviderName..."
  customChannelsJSON=$(echo -n "$(customChannels)" | tr -d '\n')

  echo -e "JSON response from $dvr:" \
  && curl -s -X PUT -H "Content-Type: application/json" -d "$customChannelsJSON" "$sourceURL"
  echo -e "\n[INFO] CDVR Custom Source creation completed for ADBTuner provider: $nativeProviderName"
}

ALL_PROVIDERS=(app_nbc app_cbs app_foxone app_pbs app_pbskids app_espn app_nfl app_hgtv app_cnn app_tbs app_tnt app_trutv app_ae app_history app_fyi app_lifetime app_amc app_cnbc app_msnow app_disneyplus app_hbomax app_cbssports)

declare -A ALT_PACKAGE_OVERRIDES
ALT_PACKAGE_OVERRIDES=(
  [app_nbc]="com.onemainstream.nbcunivers.android"
  [app_espn]="com.espn.gtv"
  [app_amc]="com.amctve.amcfiretv"
  [app_cnn]="com.cnn.mobile.fire.tv"
  [app_lifetime]="com.aetn.lifetime.watch"
  [app_ae]="com.aetn.aetv.watch"
  [app_history]="com.aetn.history.watch"
  [app_hgtv]="tv.accedo.hgtv"
  [app_trutv]="com.turner.truTV"
  [app_fyi]="com.aetn.fyi.watch"
  [app_cnbc]="com.nbcuni.cnbc.tve"
  [app_msnow]="com.nbcnews.msnbc"
  [app_hbomax]="com.hbo.hbonow"
  [app_cbssports]="com.handmark.sportcaster"
)

main() {
  if [[ "$nativeProviderName" == "remove_only" ]]; then
    [[ "$nativeRemove" != "none" ]] && deleteExistingNative
    exit 0
  fi

  registerNativeRepo

  if [[ "$nativeProviderName" == "ALL" ]]; then
    local nativeJSON
    echo -e "\n[INFO] Fetching native channel data from GitHub..."
    if ! nativeJSON=$(curl -fsS "$NATIVE_JSON_URL"); then
      echo "[ERROR] Failed to fetch native channel JSON from GitHub"
      exit 1
    fi
    nativeProviderName="native"
    [[ "$nativeRemove" != "none" ]] && deleteExistingNative && echo
    createNativeChannels "$nativeJSON"
    cdvrCustomSource
  else
    [[ "$nativeRemove" != "none" ]] && deleteExistingNative && echo
    createNativeChannels
    cdvrCustomSource
  fi
}

main
