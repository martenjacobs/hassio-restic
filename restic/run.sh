#!/bin/bash
set -e

echo -n "password" | passwd --stdin

CONFIG_PATH=/data/options.json


ls -al /config
ls -al /ssl
ls -al /addons
ls -al /backup
ls -al /share
ls -al /media

#exec restic

/usr/sbin/sshd -D
