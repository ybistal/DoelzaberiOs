#!/bin/sh
set -eu

BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

_suffix=
if [ -n "${BR2_CONFIG:-}" ] && [ -f "$BR2_CONFIG" ] &&
	grep -q '^BR2_TOOLCHAIN_BUILDROOT_GLIBC=y' "$BR2_CONFIG"
then
	_suffix=-glibc
fi

cp -f "${BOARD_DIR}/grub.cfg" "${BINARIES_DIR}/grub-esp.cfg"

rm -rf "${GENIMAGE_TMP}"
genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

cp -f "${BINARIES_DIR}/rootfs.iso9660" "${BINARIES_DIR}/doelzaberi${_suffix}.iso"
cp -f "${BINARIES_DIR}/sdcard.img"     "${BINARIES_DIR}/doelzaberi${_suffix}-sd.img"

rm -rf "${GENIMAGE_TMP}"

exit 0
