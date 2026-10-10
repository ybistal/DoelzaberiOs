#!/bin/sh

set -eu

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }
note() { printf '  %s\n' "$*"; }

_self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$_self_dir/.." && pwd)

TREE=${1:-$REPO_DIR/buildroot}
VERSION=${2:-1.0}

case "$TREE" in
	/*) ;;
	*) TREE=$(pwd)/$TREE ;;
esac

_found=no
for _output in output output-glibc; do
	case "$_output" in
	output)       _suffix= ;;
	output-glibc) _suffix=-glibc ;;
	esac
	SRC="$TREE/$_output/images"
	[ -d "$SRC" ] || continue

	OUT="$REPO_DIR/release/doelzaberi-$VERSION$_suffix"
	mkdir -p "$OUT"
	_copied=no
	for _file in "doelzaberi$_suffix.iso" "doelzaberi$_suffix-sd.img" bzImage rootfs.cpio; do
		[ -f "$SRC/$_file" ] || continue
		cp "$SRC/$_file" "$OUT/"
		note "$_file"
		_copied=yes
	done
	if [ "$_copied" != "yes" ]; then
		rmdir "$OUT" 2>/dev/null || true
		continue
	fi
	_found=yes

	(cd "$OUT" && for _file in ./*.iso ./*.img bzImage rootfs.cpio; do
		[ -f "$_file" ] || continue
		sha256sum "$_file"
	done >SHA256SUMS)
	[ -s "$OUT/SHA256SUMS" ] || die "cannot write $OUT/SHA256SUMS"

	printf '\n%s\n' "release/doelzaberi-$VERSION$_suffix"
	(cd "$OUT" && ls -l)
	printf '\n'
	cat "$OUT/SHA256SUMS"
done

[ "$_found" = "yes" ] || die "no images found in $TREE - build first (./build.sh)"
