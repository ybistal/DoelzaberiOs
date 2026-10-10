#!/bin/sh

set -eu

BUILDROOT_REPO=${BUILDROOT_REPO:-https://github.com/buildroot/buildroot.git}
BUILDROOT_REF=${BUILDROOT_REF:-ea9d29a8afd6026b2aa042526387f084eb00f359}

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TREE=$REPO_DIR/buildroot
JOBS=$(nproc 2>/dev/null || echo 4)
HOME_URL=${DOELZABERI_HOME_URL:-}
LIBC=${DOELZABERI_LIBC:-musl}
CLEAN=no
CONFIGURE_ONLY=no

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }
step() { printf '\n=== %s\n' "$*"; }

usage() {
	cat <<'EOF'
Usage: ./build.sh [options]

  -b DIR   Buildroot tree to use or create   (default: <repo>/buildroot)
  -r REF   Buildroot revision to check out   (default: the pinned commit)
  -j N     parallel jobs                     (default: all cores)
  -l LIBC  libc of the images: musl or glibc  (default: musl)
  -u URL   HOME_URL for /usr/lib/os-release  (default: none)
  -c       clean: remove the output/ of the tree first
  -n       configure only, do not build the images
  -h       this help

Environment: BUILDROOT_REPO, BUILDROOT_REF, BR2_DL_DIR, DOELZABERI_LIBC.

The musl build uses <tree>/output, the glibc build <tree>/output-glibc, so
the two can be built one after the other without touching each other.

Examples:
  ./build.sh                       # everything, with all cores
  ./build.sh -l glibc              # the glibc variant
  ./build.sh -j 8 -u https://example.org/doelzaberi
  ./build.sh -n                    # only configure (checks the defconfig)
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-b) [ $# -ge 2 ] || die "-b needs a directory"; TREE=$2; shift 2 ;;
		-r) [ $# -ge 2 ] || die "-r needs a revision"; BUILDROOT_REF=$2; shift 2 ;;
		-j) [ $# -ge 2 ] || die "-j needs a number"; JOBS=$2; shift 2 ;;
		-l) [ $# -ge 2 ] || die "-l needs a libc"; LIBC=$2; shift 2 ;;
		-u) [ $# -ge 2 ] || die "-u needs a URL"; HOME_URL=$2; shift 2 ;;
		-c) CLEAN=yes; shift ;;
		-n) CONFIGURE_ONLY=yes; shift ;;
		-h|--help) usage; exit 0 ;;
		*) die "unknown option '$1' (try --help)" ;;
	esac
done

case "$LIBC" in
	musl)
		DEFCONFIG=DoelzaberiOS_defconfig
		OUTPUT=
		IMAGE_SUFFIX=
		;;
	glibc)
		DEFCONFIG=DoelzaberiOS_glibc_defconfig
		OUTPUT=output-glibc
		IMAGE_SUFFIX=-glibc
		;;
	*)
		die "'$LIBC' is not a libc - use musl or glibc"
		;;
esac

case "$TREE" in
	/*) ;;
	*) TREE=$(pwd)/$TREE ;;
esac

[ "$(id -u)" != "0" ] || die "Buildroot must not be built as root"
for _tool in git make; do
	command -v "$_tool" >/dev/null 2>&1 || die "$_tool is required"
done
[ -x "$REPO_DIR/scripts/apply-to-buildroot.sh" ] ||
	die "scripts/apply-to-buildroot.sh is missing or not executable"

step "Buildroot tree: $TREE"
printf '  libc %s, defconfig %s, output %s\n' "$LIBC" "$DEFCONFIG" "${OUTPUT:-output}"
if [ -d "$TREE/.git" ]; then
	printf '  reusing the existing checkout\n'
	git -C "$TREE" remote set-url origin "$BUILDROOT_REPO" 2>/dev/null ||
		git -C "$TREE" remote add origin "$BUILDROOT_REPO"
else
	if [ -e "$TREE" ] && [ -n "$(ls -A "$TREE" 2>/dev/null)" ]; then
		die "$TREE is not empty and is not a git checkout"
	fi
	printf '  fetching %s\n' "$BUILDROOT_REF"
	git init --quiet "$TREE"
	git -C "$TREE" remote add origin "$BUILDROOT_REPO"
	git -C "$TREE" fetch --depth 1 origin "$BUILDROOT_REF" ||
		die "cannot fetch $BUILDROOT_REF from $BUILDROOT_REPO"
	git -C "$TREE" checkout --quiet --detach FETCH_HEAD
fi

step "Applying DoelzaberiOS"
"$REPO_DIR/scripts/apply-to-buildroot.sh" "$TREE"

if [ "$CLEAN" = "yes" ]; then
	step "Removing $TREE/${OUTPUT:-output}"
	rm -rf "$TREE/${OUTPUT:-output}"
fi

if [ -n "$HOME_URL" ]; then
	export DOELZABERI_HOME_URL="$HOME_URL"
	printf '\nHOME_URL=%s goes into /usr/lib/os-release\n' "$HOME_URL"
fi

if [ -n "$OUTPUT" ]; then
	MAKE_O="O=$TREE/$OUTPUT"
	IMAGES_DIR="$TREE/$OUTPUT/images"
else
	MAKE_O=
	IMAGES_DIR="$TREE/output/images"
fi

step "Configuring (make $DEFCONFIG, libc $LIBC)"
make -C "$TREE" $MAKE_O "$DEFCONFIG"

if [ "$CONFIGURE_ONLY" = "yes" ]; then
	step "Done (configure only)"
	printf '  cd %s && make %s-j%s\n' "$TREE" "${MAKE_O:+$MAKE_O }" "$JOBS"
	exit 0
fi

step "Building with $JOBS jobs"
make -C "$TREE" $MAKE_O -j"$JOBS"

step "Images in $IMAGES_DIR"
for _image in "doelzaberi${IMAGE_SUFFIX}.iso" "doelzaberi${IMAGE_SUFFIX}-sd.img" bzImage rootfs.cpio; do
	[ -f "$IMAGES_DIR/$_image" ] &&
		ls -l "$IMAGES_DIR/$_image" || true
done
printf '\nsha256:\n'
(cd "$IMAGES_DIR" && for _image in "doelzaberi${IMAGE_SUFFIX}.iso" "doelzaberi${IMAGE_SUFFIX}-sd.img" bzImage; do
	[ -f "$_image" ] && sha256sum "$_image"
done) || true
