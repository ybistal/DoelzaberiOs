#!/bin/sh

set -eu

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }

_self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$_self_dir/.." && pwd)
cd "$REPO_DIR"

FAILED=0
ok()   { printf '  ok    %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; FAILED=1; }
skip() { printf '  skip  %s\n' "$*"; }

echo '== POSIX shell syntax (sh -n)'
for _file in \
	build.sh \
	scripts/*.sh \
	board/doelzaberi/post-build.sh \
	board/doelzaberi/post-image.sh \
	board/doelzaberi/rootfs-overlay/usr/bin/doelzaberi-gui \
	board/doelzaberi/rootfs-overlay/etc/init.d/doelzaberi-runtime \
	board/doelzaberi/rootfs-overlay/etc/profile.d/doelzaberi-env.sh
do
	[ -e "$_file" ] || continue
	if sh -n "$_file" 2>/tmp/lint.err; then
		ok "$_file"
	else
		bad "$_file"
		cat /tmp/lint.err >&2
	fi
done

echo '== the installer (sh -n)'
if sh -n board/doelzaberi/rootfs-overlay/usr/sbin/doelzaberi-install; then
	ok 'doelzaberi-install'
else
	bad 'doelzaberi-install'
fi

echo '== shellcheck'
if command -v shellcheck >/dev/null 2>&1; then
	for _file in build.sh scripts/*.sh \
		board/doelzaberi/post-build.sh \
		board/doelzaberi/rootfs-overlay/usr/sbin/doelzaberi-install \
		board/doelzaberi/rootfs-overlay/usr/bin/doelzaberi-gui
	do
		[ -e "$_file" ] || continue
		if shellcheck -S error "$_file"; then
			ok "$_file"
		else
			bad "$_file"
		fi
	done
else
	skip 'shellcheck is not installed'
fi

echo '== GRUB configuration'
if command -v grub-script-check >/dev/null 2>&1; then
	for _file in board/doelzaberi/grub.cfg \
		board/doelzaberi/grub-efi.cfg \
		board/doelzaberi/rootfs-overlay/etc/default/grub
	do
		[ -e "$_file" ] || continue
		if grep -q '^menuentry ' "$_file"; then
			if grub-script-check "$_file"; then
				ok "$_file"
			else
				bad "$_file"
			fi
		else
			skip "$_file (no menuentry, not a GRUB script)"
		fi
	done
else
	skip 'grub-script-check is not installed'
fi

echo '== defconfig sanity'
for _fragment in board/doelzaberi/linux-*.fragment; do
	if grep -qE '^CONFIG_[A-Z0-9_]+=' "$_fragment"; then
		ok "$_fragment"
	else
		bad "$_fragment"
	fi
done
if grep -q 'BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=.*linux-storage.fragment' \
	configs/DoelzaberiOS_defconfig
then
	ok 'the storage fragment is part of the defconfig'
else
	bad 'the storage fragment is missing from the defconfig'
fi
if grep -q 'BR2_LINUX_KERNEL_CONFIG_FRAGMENT_FILES=.*linux-storage.fragment' \
	configs/DoelzaberiOS_defconfig &&
	grep -qE '^CONFIG_BLK_DEV_NVME=y' \
	board/doelzaberi/linux-storage.fragment
then
	ok 'NVMe support is requested by the defconfig'
else
	bad 'NVMe support is missing'
fi

echo '== the libc variants'
for _defconfig in configs/DoelzaberiOS_defconfig configs/DoelzaberiOS_glibc_defconfig; do
	if [ -f "$_defconfig" ]; then
		ok "$_defconfig"
	else
		bad "$_defconfig is missing"
	fi
done
if grep -q '^BR2_TOOLCHAIN_BUILDROOT_MUSL=y' configs/DoelzaberiOS_defconfig &&
	grep -q '^BR2_TOOLCHAIN_BUILDROOT_GLIBC=y' configs/DoelzaberiOS_glibc_defconfig
then
	ok 'the defconfigs select musl and glibc'
else
	bad 'the defconfigs do not select musl and glibc'
fi
_drift=$(diff -u configs/DoelzaberiOS_defconfig configs/DoelzaberiOS_glibc_defconfig |
	grep -E '^[+-][^+-]' |
	grep -vE 'TOOLCHAIN_BUILDROOT_(MUSL|GLIBC)|GENERATE_LOCALE|MESA3D_GALLIUM_DRIVER_R600' ||
	true)
if [ -z "$_drift" ]; then
	ok 'the defconfigs differ only in the libc and the extra drivers'
else
	bad 'the defconfigs have drifted apart'
	printf '%s\n' "$_drift" >&2
fi

echo '== the Wayland session'
for _compositor in hyprland niri; do
	if grep -q "$_compositor" board/doelzaberi/rootfs-overlay/usr/sbin/doelzaberi-install &&
		grep -q "$_compositor" board/doelzaberi/rootfs-overlay/usr/bin/doelzaberi-gui
	then
		ok "$_compositor is offered by the installer and started by doelzaberi-gui"
	else
		bad "$_compositor is not handled by the installer and doelzaberi-gui"
	fi
done
if grep -qE '^hyprland$' board/doelzaberi/rootfs-overlay/etc/doelzaberi/compositor; then
	ok 'the compositor of a fresh system is hyprland'
else
	bad 'board/doelzaberi/rootfs-overlay/etc/doelzaberi/compositor is missing'
fi

echo
if [ "$FAILED" = 0 ]; then
	echo 'lint: everything passed'
else
	die 'lint: there were failures'
fi
