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

echo
if [ "$FAILED" = 0 ]; then
	echo 'lint: everything passed'
else
	die 'lint: there were failures'
fi
