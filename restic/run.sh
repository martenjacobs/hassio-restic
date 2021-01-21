#!/usr/bin/with-contenv bashio

set -e

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

# run the backup
(
  cd /hassos-data/supervisor
  restic --verbose backup .
)
