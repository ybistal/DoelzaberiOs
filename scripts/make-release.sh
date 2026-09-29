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

SRC="$TREE/output/images"
[ -d "$SRC" ] || die "$SRC does not exist - build first (./build.sh)"

OUT="$REPO_DIR/release/doelzaberi-$VERSION"
mkdir -p "$OUT"

for _file in doelzaberi.iso doelzaberi-sd.img bzImage rootfs.cpio; do
	[ -f "$SRC/$_file" ] || continue
	cp "$SRC/$_file" "$OUT/"
	note "$_file"
done

[ -f "$OUT/doelzaberi.iso" ] || [ -f "$OUT/doelzaberi-sd.img" ] ||
	die "no images found in $SRC"

(cd "$OUT" && for _file in ./*.iso ./*.img bzImage rootfs.cpio; do
	[ -f "$_file" ] && sha256sum "$_file"
done >SHA256SUMS)
[ -s "$OUT/SHA256SUMS" ] || die "cannot write $OUT/SHA256SUMS"

printf '\n%s\n' "release/doelzaberi-$VERSION"
(cd "$OUT" && ls -l)
printf '\n'
cat "$OUT/SHA256SUMS"
