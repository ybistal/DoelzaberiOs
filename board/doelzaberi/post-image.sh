#!/bin/sh
set -eu

BOARD_DIR="$(dirname "$0")"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

cp -f "${BOARD_DIR}/grub.cfg" "${BINARIES_DIR}/grub-esp.cfg"

rm -rf "${GENIMAGE_TMP}"
genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

cp -f "${BINARIES_DIR}/rootfs.iso9660" "${BINARIES_DIR}/doelzaberi.iso"
cp -f "${BINARIES_DIR}/sdcard.img"     "${BINARIES_DIR}/doelzaberi-sd.img"

rm -rf "${GENIMAGE_TMP}"

exit 0
