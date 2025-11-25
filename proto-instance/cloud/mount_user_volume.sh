#!/usr/bin/env bash

set -eE

HOME_BACKUP=/home.bak
die() {
  line_no=$1
  if [ -d $HOME_BACKUP ]; then
    mv $HOME_BACKUP /home
  fi
  echo "Died at $line_no in $(realpath $0)"
}
trap 'die $LINENO' ERR

# Select the device that has no boot partition
USER_BLOCK_DEVICE_QUERY=$(
cat <<EOF
.blockdevices[]
  | select(isempty(.children // empty) or all(
      .children[]?.mountpoint // empty; startswith("/boot") | not
    )
  ).path
EOF
)

device_exists=1
num_partitions=0

sleep_time_sec=5
for i in {1..10}
do
  device_name=$(
    lsblk -o 'MOUNTPOINT,NAME,PATH' --json | jq -r "${USER_BLOCK_DEVICE_QUERY}"
  )
  if [ -n "${device_name}" ]; then
    echo "[+] Checking that block device ${device_name} is attached"
    fdisk -l $device_name && break || echo "${device_name} not found, sleeping for ${sleep_time_sec} sec"
  fi
  sleep $sleep_time_sec
  sleep_time_sec=$(( 3 * sleep_time_sec / 2)) # exponential backoff by factor of 1.5
done

if [ -z "${device_name}" ]; then
  echo "Couldn't find non-boot partition. Dying now."
  exit 1
fi

echo "[+] Checking for existing partitions"
num_partitions=$(
  lsblk $device_name -J | jq -r '[.blockdevices[]?.children[]? | select(.type == "part")] | length'
)

if (( $num_partitions < 1)); then
  echo "[+] Partitioning ${device_name}"
  parted -s $device_name -- mklabel gpt \
    mkpart main ext4 1MiB -1

  echo "[+] Making a file system on ${partition_name}"
  partprobe $device_name
  partition_name=$(
    lsblk $device_name -o NAME,PATH --json | jq -r '.blockdevices[0].children[0].path'
  )
  mkfs.ext4 $partition_name
else
  echo "[+] Found ${num_partitions} partition(s) on ${device_name}"
  echo "[+] This is probably because this block device has already been partitioned and formatted"

  partition_name=$(
    lsblk $device_name -o NAME,PATH --json | jq -r '.blockdevices[0].children[0].path'
  )
fi

echo "[+] Mounting ${partition_name} as /home"
home_mode=$(stat -c "%a" /home)
mv /home $HOME_BACKUP
mkdir -m="${home_mode}" /home
mount $partition_name /home

echo "[+] Making entry in fstab"
echo "${partition_name} /home ext4 defaults 0 2" >> /etc/fstab

echo "[+] Copying old home directory to new one"
rsync -a "${HOME_BACKUP}/" /home/

echo "[+] Cleaning up"
if [ -d "/home/$(whoami)" ]; then
  rm -rdf $HOME_BACKUP
fi