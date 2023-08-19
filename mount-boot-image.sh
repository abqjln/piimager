#!/bin/bash -e
#
# mount-boot-image.sh
#
if [[ "${EUID}" -ne "0" || ! -f "${1}" || -z "${2}" ]]; then
	printf "Usage: sudo %s <IMAGE_IMG> <TMPBOOT_DIR>\n" $(basename "${0}")
	exit 1
fi
IMAGE_IMG="${1}"
TMPBOOT_DIR="${2}"

# Get the starting sector of the first DOS partition from the image
BOOTSTARTSECTOR=`fdisk -l "${IMAGE_IMG}" | sed -nr "s/^\S+1\s+([0-9]+).*  c W95 FAT32 \(LBA\)$/\1/p"`

# Get sector size
SECTORSIZE=$(fdisk -l "${IMAGE_IMG}" |  grep "Sector size" | awk '{print $4}')

# Mount image in temporary TMPBOOT_DIR directory using loop
losetup /dev/loop0 "${IMAGE_IMG}" -o $((${BOOTSTARTSECTOR}*${SECTORSIZE}))
mkdir -p ${TMPBOOT_DIR}
mount /dev/loop0 ${TMPBOOT_DIR}

exit 0
