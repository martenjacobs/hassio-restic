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

/usr/sbin/sshd -D
