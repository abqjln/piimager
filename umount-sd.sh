#!/bin/bash
#
# umount-sd.sh
#
if [[ "${EUID}" -ne "0" || -z "${1}" ]]; then
	printf "Usage: sudo %s <e.g., /dev/mmcblk0>\n" $(basename "${0}")
	exit 1
fi

# Unmount any (auto-)mounted partitions on the device
RESULT=$(df | grep ${1})
while [[ -n "${RESULT}" ]]; do
	# Unmount the first line in the df output
	MOUNTPOINT=$(df | grep "${1}" | awk 'NR==1{ print $6 }')
	printf "Unmounting %s\n" "${MOUNTPOINT}"
	sudo umount "${MOUNTPOINT}"
	RESULT=$(df | grep ${1})
done

exit 0
