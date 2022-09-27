#!/bin/bash
#
#
# https://beamnetworks.dev
# CREATED BY: cole@beamnetworks.dev
#
#

# SET MANUAL DESTINATION FOR BACKUP
dest="user@host.local"
path="/mnt/md0/backups/server/nginxbackups"

echo " COMPRESSING TEMP FOLDER "
backupdate="$(date +'%Y-%m-%d-%s')"

echo " BACKUP NAME = $backupdate "
sudo zip -r wireguard-backup-$backupdate.zip /etc/wireguard/
cd

echo " COPYING BACKUP TO SERVER "
sudo scp wireguard-backup-$backupdate.zip $dest:$path

echo " REMOVING COMPRESSED BACKUP "
sudo wireguard-backup-$backupdate.zip

echo " DONE! "
