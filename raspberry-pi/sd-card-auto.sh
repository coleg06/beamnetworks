#!/bin/bash
#
# StorPi v1.0.1
#
# BEAM NETWORKS x COLE GOOD
# Copyright 2023 beamnetworks.dev
#

conf_script="/home/beamnetworks/storpi.conf"
. $conf_script
echo "Finding available disks.."
disks="$(sudo fdisk -l | awk '/Apple HFS\/HFS+/ {print $1}')"
echo $disks
hostname="$(hostname)"

output=$(echo $disks)

if [ "$COPY_METHOD" = "SMB" ]; then
    echo "Mounting SMB share"
    mkdir -p $SMB_MOUNT_POINT
    mount -t cifs -o "username=$SMB_USER,password=$SMB_PASSWORD" "//$SMB_SERVER/$SMB_SHARE" "$SMB_MOUNT_POINT"
    BACKUP_DIR="$SMB_MOUNT_POINT"
    echo "Unmounting SMB share"
    echo "Backup directory location: $BACKUP_DIR"
fi

echo "Reading exsisting UUIDs from backup file"
readarray -t backed_up_uuids < "$uuid_file"

while IFS= read -r line; do
  echo  "$line"

  rawdevice="${line#/dev/}"

  device_uuid="$(blkid -s UUID -o value "$line")"

  used_storage="$(df -h $line | awk 'NR==2{print $3}')"

  echo "Used storage on card: $used_storage"

  echo "Checking if device UUID is in the list of backed up UUIDs"
  if [[ " ${backed_up_uuids[*]} " =~ " ${device_uuid} " ]]; then
    echo "Device with UUID $device_uuid has already been backed up. Skipping..."
    continue
  fi

  echo "Creating mount point ${BACKUP_DIR}/${rawdevice}"

  mkdir -p ${BACKUP_DIR}/${rawdevice}

  echo "Mounting device"
  mount $line /mnt/tmp/$rawdevice
  echo "Mounted!"

  bkdate="$(date +%Y%m%d_%H%M%S)"
  echo "Backup time: $bkdate"

  echo "Creating backup directory"
  mkdir -p ${BACKUP_DIR}/sdcard/$bkdate

  echo "Copying backup of SD card"
  cp -r /mnt/tmp/$rawdevice ${BACKUP_DIR}/sdcard/$bkdate

  echo "Unmounting SD card"
  umount /mnt/tmp/$rawdevice

  if [ "$COPY_ALERT" = "SENDGRID" ]; then
    bash send-email.sh "Backup has been completed for SD cards at $LOCATION.\n\nCard UUID: $device_uuid\nBackup Directory: ${BACKUP_DIR}/sdcard/$bkdate\nUsed Storage: $used_storage" "StorPi: Transfer Complete"
  fi

  curl \
      --silent \
      -d '{"hostname":"'$hostname'","event":"mission_complete","device_uuid":"'$device_uuid'"}' \
      -H "Content-Type: application/json" \
      -X POST https://check-in.storpi.beamnetworks.dev/storpi/mission-complete \
      --output /dev/null

  echo "Adding current device UUID to the UUID file"
  echo "$device_uuid" >> "$uuid_file"

done <<< "$output"

echo "Checking if UUIDs can be removed from the UUID file"
for backed_up_uuid in "${backed_up_uuids[@]}"; do
  if [[ ! " ${present_uuids[*]} " =~ " ${backed_up_uuid} " ]]; then
    echo "Disk with UUID $backed_up_uuid is not present. Removing from the backup list..."
    sed -i "/$backed_up_uuid/d" "$uuid_file"
  fi
done

if [ "$COPY_METHOD" = "SMB" ]; then
  echo "Unmounting SMB share"
  umount $BACKUP_DIR
fi

echo "Complete!"

curl \
    --silent \
    -d '{"hostname":"'$hostname'","event":"hello"}' \
    -H "Content-Type: application/json" \
    -X POST https://check-in.storpi.beamnetworks.dev/storpi/hello \
    --output /dev/null
