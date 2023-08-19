#!/bin/bash -e
#
# create-image.sh
# Creates PiOS image with customizations added during first boot
#

# Can use any recent stable image--will update after booting anyway
# https://downloads.raspberrypi.org
IMAGE32_URL="https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-05-03/2023-05-03-raspios-bullseye-armhf-lite.img.xz"
IMAGE64_URL="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-05-03/2023-05-03-raspios-bullseye-arm64-lite.img.xz"

TARGET="${1}"
BITS="${2}"
pushd $(dirname $(realpath "$0")) > /dev/null
TMP_BOOTDIR="./boot"

if [[ "${EUID}" -ne "0" || -z "${TARGET}" || ! -f "./firstrun.sh.cfg" ]]; then
	printf "Note: must run from directory containing images and firstrun.sh.cfg\n"
	printf "Usage: sudo %s <target> <32/64>\n" $(basename "${0}")
	exit 1
elif [[ "${BITS}" = "32" ]]; then
	IMAGE_URL="${IMAGE32_URL}"
elif [[ "${BITS}" = "64" ]]; then
	IMAGE_URL="${IMAGE64_URL}"
else
	printf "Usage: sudo %s <target> <32/64>\n" $(basename "${0}")
	exit 1
fi

# Download if not done already
if [[ ! -f "$(basename "${IMAGE_URL}")" ]]; then
	printf "Downloading ${IMAGE_URL}\n"
	curl -L "${IMAGE_URL}" -o "$(basename "${IMAGE_URL}")"
else
	printf "Reusing $(basename "${IMAGE_URL}")\n"
fi

# Decompress image if not done already
if [[ ! -f "$(basename "${IMAGE_URL}" .xz )" ]]; then
	# Decompress image and keep original
	printf "Decomressing ${IMAGE_URL}\n"
	xz -k -d "$(basename "${IMAGE_URL}")"
else
	printf "Reusing $(basename "${IMAGE_URL}" .xz )\n"
fi

# If no previous *-$BITS}.img, create one, otherwise mv
OLDIMG=$(ls *-"${BITS}".img 2> /dev/null | xargs | awk '{print $1}')
if [[ -z "${OLDIMG}" ]]; then
	cp "$(basename "${IMAGE_URL}" .xz )" "${TARGET}"-"${BITS}".img
else
	# No error message and returns 0 even if same file (may be changing parms)
	mv "${OLDIMG}" "${TARGET}"-"${BITS}".img 2> /dev/null || true
fi

###### Configure boot image
# Initial boot--will run init line and resize partitions, generate ssh keys
# 2nd boot--will boot to hostname:rasperrypi and default user (was pi, now script??). Runs firstrun.sh
# 3nd boot--boots to new configuration, (finishes resizing--??)
#
# Copy firstrun.sh.cfg to firstrun.sh then sed secrets
# Copy /boot/cmdline.txt to /boot/cmdline.txt.orig then sed
# Both of these can be reapplied to previously updated images
#
# image-secrets.src contains env vars "S_xxx" will be updated by sed later

# Example:
# image-secrets.src
#
# S_LOCALE_LINE="en_US.UTF-8 UTF-8"
# S_TZ="America/Denver"
# S_KBSYMBOLS="us" (lowercase)
#
# S_USER=zzz
# S_PWD='user-pwd'
#
# S_WIFICOUNTRY=US #(uppercase)
# S_SSID=xxxx
# S_PSK=yyyy

#

# You can change path...
source ../../secrets/image-secrets.src

# Mount boot image
printf "Mounting %s..." "${TMP_BOOTDIR}"
./mount-boot-image.sh "${TARGET}"-"${BITS}".img "${TMP_BOOTDIR}"

###### firstrun.sh
printf "configuring firstrun.sh..."
if [[ ! -f ${TMP_BOOTDIR}/firstrun.sh.orig ]]; then
	if [[ -f ${TMP_BOOTDIR}/firstrun.sh ]]; then
		cp ${TMP_BOOTDIR}/firstrun.sh ${TMP_BOOTDIR}/firstrun.sh.orig
	fi
fi
cp firstrun.sh.cfg ${TMP_BOOTDIR}/firstrun.sh
chmod 700 ${TMP_BOOTDIR}/firstrun.sh

# Change target info
sed -i "s|TARGET|"${TARGET}"|g" ${TMP_BOOTDIR}/firstrun.sh
sed -i "s|S_LOCALE_LINE|\"${S_LOCALE_LINE}\"|g" ${TMP_BOOTDIR}/firstrun.sh
sed -i "s|S_KBSYMBOLS|"${S_KBSYMBOLS}"|g" ${TMP_BOOTDIR}/firstrun.sh
sed -i "s|S_TZ|"${S_TZ}"|g" ${TMP_BOOTDIR}/firstrun.sh

# Change wifi
sed -i "s|S_WIFICOUNTRY|"${S_WIFICOUNTRY}"|g" ${TMP_BOOTDIR}/firstrun.sh
sed -i "s|S_SSID|"${S_SSID}"|g" ${TMP_BOOTDIR}/firstrun.sh
sed -i "s|S_PSK|"${S_PSK}"|g" ${TMP_BOOTDIR}/firstrun.sh

# User
sed -i "s|S_USER|"${S_USER}"|g" ${TMP_BOOTDIR}/firstrun.sh
sed -i "s|S_PWD|"${S_PWD}"|g" ${TMP_BOOTDIR}/firstrun.sh


###### cmdline.txt
printf "configuring cmdline.txt..."
if [[ ! -f ${TMP_BOOTDIR}/cmdline.txt.orig ]]; then
	cp ${TMP_BOOTDIR}/cmdline.txt ${TMP_BOOTDIR}/cmdline.txt.orig
fi
# Update
cp ${TMP_BOOTDIR}/cmdline.txt.orig ${TMP_BOOTDIR}/cmdline.txt
cat >> ${TMP_BOOTDIR}/cmdline.txt <<'CMDEOF'
systemd.run=/boot/firstrun.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target
CMDEOF
tr '\n' ' ' < ${TMP_BOOTDIR}/cmdline.txt > ${TMP_BOOTDIR}/tmpfile && mv ${TMP_BOOTDIR}/tmpfile ${TMP_BOOTDIR}/cmdline.txt


# Umount boot image
printf "unmounting %s\n" "${TMP_BOOTDIR}"
./umount-boot-image.sh "${TMP_BOOTDIR}"
###### End Configure boot image

popd > /dev/null
printf "Successfully created %s\n" ""${TARGET}"-"${BITS}".img"
exit 0

