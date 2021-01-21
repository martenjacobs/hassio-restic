#!/bin/bash
set -e

echo "root:password" | chpasswd

CONFIG_PATH=/data/options.json


ls -al /config
ls -al /ssl
ls -al /addons
ls -al /backup
ls -al /share
ls -al /media

#exec restic

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

udevd --daemon && sleep 0.5
udevadm trigger

/usr/sbin/sshd -D
