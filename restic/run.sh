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
)|| true
# Temporary ssh related stuff
echo "root:password" | chpasswd
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
	# generate fresh rsa key
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
	# generate fresh dsa key
	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

#prepare run dir
if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi

#cat /etc/ssh/sshd_config | grep "^[^#]"

cat <<EOF > /etc/ssh/sshd_config
PermitRootLogin yes
AuthorizedKeysFile	.ssh/authorized_keys
AllowTcpForwarding no
GatewayPorts no
X11Forwarding no
Subsystem	sftp	/usr/lib/ssh/sftp-server
EOF

/usr/sbin/sshd -D
