#!/usr/bin/with-contenv bashio
echo "HassOS restic add-on starting"
date
set -e

mkdir -p /data/restic-cache

# find and mount the data partition
udevd --daemon && sleep 0.5
udevadm trigger && sleep 0.5
mkdir /hassos-data
mount /dev/disk/by-label/hassos-data /hassos-data/

# load configuration
CONFIG_PATH=/data/options.json
$(jq -r \
  '.env_vars|to_entries[]|"export " + .key + "=" + (.value|tostring) + ""' \
  "$CONFIG_PATH")
jq -r \
  '.exclude_patterns[]|.' \
  "$CONFIG_PATH" > /exclude_file
# run the backup
(
  cd /hassos-data/supervisor
  restic \
    --cache-dir=/data/restic-cache \
    --verbose \
    --exclude-file=/exclude_file \
    backup .
)

echo "Done"
