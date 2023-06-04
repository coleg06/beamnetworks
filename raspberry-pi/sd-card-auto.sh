# COPYRIGHT 2023 BEAM NETWORKS x COLE GOOD
# ALL RIGHTS RESERVED
#
#!/bin/bash

uuid_file="/home/beamnetworks/stored-variables/uuids.txt"
echo "Finding available disks.."
disks="$(sudo fdisk -l | awk '/Apple HFS\/HFS+/ {print $1}')"
echo $disks

output=$(echo $disks)

mount -t cifs -o "username=REDACTED,password=REDACTED" "//REDACTED/backups" "/mnt/smb"

# Read the existing backup UUIDs from the backup list file
readarray -t backed_up_uuids < "$uuid_file"

# Loop through each line of the output
while IFS= read -r line; do
  # Process each line and use it as input for the next command
  echo  "$line"

  rawdevice="${line#/dev/}"


  device_uuid="$(blkid -s UUID -o value "$line")"

  # Check if the device UUID is in the list of backed up UUIDs
  if [[ " ${backed_up_uuids[*]} " =~ " ${device_uuid} " ]]; then
    echo "Device with UUID $device_uuid has already been backed up. Skipping..."
    continue
  fi

  echo "Creating mount point /mnt/tmp/$rawdevice"

  mkdir -p /mnt/tmp/$rawdevice

  echo "Mounting device"

  mount $line /mnt/tmp/$rawdevice

  echo "Mounted!"

  echo "Creating backup directory"

  bkdate="$(date +%Y%m%d_%H%M%S)"

  mkdir -p /mnt/smb/sdcard/$bkdate

  cp -r /mnt/tmp/$rawdevice /mnt/smb/sdcard/$bkdate

  echo "Unmounting SD card"

  umount /mnt/tmp/$rawdevice

  # Append the device UUID to the list of backed up UUIDs
  echo "$device_uuid" >> "$uuid_file"

done <<< "$output"

# Remove UUIDs from the backup list if the disks are not present
for backed_up_uuid in "${backed_up_uuids[@]}"; do
  if [[ ! " ${present_uuids[*]} " =~ " ${backed_up_uuid} " ]]; then
    echo "Disk with UUID $backed_up_uuid is not present. Removing from the backup list..."
    sed -i "/$backed_up_uuid/d" "$uuid_file"
  fi
done


echo "Unmounting SMB share"

umount /mnt/smb

echo "Complete!"
