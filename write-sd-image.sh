#!/bin/bash -e
#
# write-sd-image.sh
# Writes an image to sdcard
#
# https://scribles.net/writing-raspbian-os-image-to-sd-card-on-linux/
#
GOODPI="pidev"

if [[ "${EUID}" != "0" ]]; then
	printf "Error: Must be run as sudo.\n"
	printf "Usage: sudo %s <image.img> </dev/mmcblk0>\n" $(basename "${0}")
	exit 1
fi
if [[ "${HOSTNAME}" != "${GOODPI}" ]]; then
	printf "Error: Can only be run on ${GOODPI}.\n"
	printf "Usage: sudo %s <image.img> </dev/mmcblk0>\n" $(basename "${0}")
	exit 1
fi
if [[ ! -f "${1}" ]]; then
	printf "Error: Image file ${1} not found in current directory.\n"
	printf "Usage: sudo %s <image.img> </dev/mmcblk0>\n" $(basename "${0}")
	exit 1
fi
if [[ -z "${2}" ]]; then
	printf "Error: Device file ${2} not found.\n"
	printf "Usage: sudo %s <image.img> </dev/mmcblk0>\n" $(basename "${0}")
	exit 1
fi

# Confirm SD disk is present (strip off /dev/)
lsblk | grep $(echo "${2}" | sed 's/\/dev\///')
RESULT=$?
if [[ "${RESULT}" -ne "0" ]]; then
	printf "Error: SD card %s not present.\n" "${2}"
	printf "Usage: sudo ./%s ./<image.img>\n" $(basename "${0}")
	exit 1
fi

# Unmount if (auto)mounted, then partition to wipe everything
./umount-sd.sh ${2}

printf "Partitioning\n"
sudo parted --script ${2} mklabel gpt

# Write to sd card
printf "Writing to sd card\n"
sudo dd bs=4M if=${1} of=${2} status=progress conv=fsync

# Unmount if (auto)mounted
./umount-sd.sh ${2}

printf "Success! You may safely remove SD card.\n"

