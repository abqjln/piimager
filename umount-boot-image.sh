#!/bin/bash -e
#
# umount-boot-image.sh
#
if [[ "${EUID}" -ne "0" || -z "${1}" ]]; then
	printf "Usage: sudo %s <tempdir>\n" $(basename "${0}")
	exit 1
fi
TMPBOOT_DIR="${1}"

# Unmount loop
sudo umount ${TMPBOOT_DIR}
sudo losetup -d /dev/loop0
sudo rmdir ${TMPBOOT_DIR}

exit 0
