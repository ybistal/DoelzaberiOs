#!/bin/sh

set -eu

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }
note() { printf '  %s\n' "$*"; }

usage() {
	cat <<'EOF'
Usage: scripts/apply-to-buildroot.sh [BUILDROOT_DIR[:REVISION]]

Copy board/, configs/ and package/ into a Buildroot tree and apply patches/ to it.

  BUILDROOT_DIR   Buildroot checkout to patch (default: <repo>/buildroot)
  REVISION        git revision to check out in that tree first

Examples:
  scripts/apply-to-buildroot.sh
  scripts/apply-to-buildroot.sh /srv/buildroot
  scripts/apply-to-buildroot.sh buildroot:ea9d29a8af
EOF
}

case "${1:-}" in
	-h|--help) usage; exit 0 ;;
esac
[ $# -le 1 ] || die "too many arguments (try --help)"

_self_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(CDPATH= cd -- "$_self_dir/.." && pwd)
PATCH_DIR="$REPO_DIR/patches"

[ -d "$PATCH_DIR" ] || die "no $PATCH_DIR"
for _dir in board configs package; do
	[ -d "$REPO_DIR/$_dir" ] || die "no $REPO_DIR/$_dir"
done

TREE=${1:-$REPO_DIR/buildroot}
REVISION=
case "$TREE" in
	*:*)
		REVISION=${TREE##*:}
		TREE=${TREE%%:*}
		;;
esac
case "$TREE" in
	/*) ;;
	*) TREE=$(pwd)/$TREE ;;
esac

if [ ! -f "$TREE/Makefile" ] || ! grep -q '^BR2_VERSION' "$TREE/Makefile"; then
	die "$TREE does not look like a Buildroot tree (Makefile with BR2_VERSION)"
fi

if [ -n "$REVISION" ]; then
	[ -d "$TREE/.git" ] || die "$TREE is not a git checkout, cannot use $REVISION"
	note "checking out $REVISION"
	git -C "$TREE" checkout --quiet --detach "$REVISION" ||
		die "cannot check out $REVISION in $TREE"
fi

BR2_VERSION=$(sed -n 's/^export BR2_VERSION := //p' "$TREE/Makefile" | head -n 1)
note "Buildroot tree   $TREE"
note "Buildroot version ${BR2_VERSION:-unknown}"

note "copying board/, configs/ and package/ into the tree"
for _dir in board configs package; do
	cp -a "$REPO_DIR/$_dir/." "$TREE/$_dir/"
done

apply_patch() {
	_patch=$1
	_name=${_patch##*/}
	if [ -d "$TREE/.git" ]; then
		if git -C "$TREE" apply --check "$_patch" 2>/dev/null; then
			git -C "$TREE" apply "$_patch" || die "cannot apply $_name"
			note "applied $_name"
		elif git -C "$TREE" apply --check --reverse "$_patch" 2>/dev/null; then
			note "$_name is already applied"
		else
			die "$_name does not apply - wrong Buildroot revision?"
		fi
	elif (cd "$TREE" && patch -p1 --dry-run --forward <"$_patch") >/dev/null 2>&1; then
		(cd "$TREE" && patch -p1 --forward <"$_patch") >/dev/null ||
			die "cannot apply $_name"
		note "applied $_name"
	elif (cd "$TREE" && patch -p1 --dry-run --reverse <"$_patch") >/dev/null 2>&1; then
		note "$_name is already applied"
	else
		die "$_name does not apply - wrong Buildroot revision?"
	fi
}

_found=no
for _patch in "$PATCH_DIR"/*.patch; do
	[ -e "$_patch" ] || break
	_found=yes
	apply_patch "$_patch"
done
[ "$_found" = "yes" ] || die "no patches found in $PATCH_DIR"

cat <<EOF

DoelzaberiOS is applied to $TREE.  Build it with:

  cd $TREE
  make DoelzaberiOS_defconfig
  make -j"$(nproc 2>/dev/null || echo 4)"
EOF
