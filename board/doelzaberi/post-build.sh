#!/bin/sh

set -eu

TARGET_DIR="$1"

sed -i 's|^\(root:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\).*$|\1/usr/bin/fish|' \
	"$TARGET_DIR/etc/passwd"

if [ -f "$TARGET_DIR/etc/shells" ]; then
	grep -q '^/usr/bin/fish$' "$TARGET_DIR/etc/shells" ||
		printf '/usr/bin/fish\n' >> "$TARGET_DIR/etc/shells"
else
	printf '/bin/sh\n/bin/bash\n/usr/bin/fish\n' > "$TARGET_DIR/etc/shells"
fi

grep -q '^wheel:' "$TARGET_DIR/etc/group" ||
	printf 'wheel:x:10:\n' >> "$TARGET_DIR/etc/group"

for _conf in "$TARGET_DIR/etc/conf.d/agetty.tty1" "$TARGET_DIR/etc/conf.d/agetty"; do
	[ -f "$_conf" ] &&
		sed -i 's/^term_type=.*/term_type="linux"/' "$_conf" || true
done
[ -f "$TARGET_DIR/etc/inittab" ] &&
	sed -i 's|\(^console::respawn:/sbin/getty .*\) vt100$|\1 linux|' "$TARGET_DIR/etc/inittab" || true

for _script in usr/bin/doelzaberi-gui etc/init.d/doelzaberi-runtime usr/sbin/autologin; do
	[ -e "$TARGET_DIR/$_script" ] &&
		chmod 0755 "$TARGET_DIR/$_script" || true
done

BOARD_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
for _bundle in "$BOARD_DIR/gui"/*.tar.gz; do
	[ -e "$_bundle" ] || continue
	mkdir -p "$TARGET_DIR/usr/share/doelzaberi/gui"
	cp -f "$_bundle" "$TARGET_DIR/usr/share/doelzaberi/gui/"
done

cat > "$TARGET_DIR/usr/lib/os-release" <<'EOF'
NAME="DoelzaberiOS"
ID=doelzaberi
ID_LIKE=buildroot
PRETTY_NAME="DoelzaberiOS 1.0"
VERSION="1.0"
VERSION_ID="1.0"
ANSI_COLOR="1;36"
EOF
if [ -n "${DOELZABERI_HOME_URL:-}" ]; then
	printf 'HOME_URL="%s"\n' "$DOELZABERI_HOME_URL" >> "$TARGET_DIR/usr/lib/os-release"
fi
ln -sfn ../usr/lib/os-release "$TARGET_DIR/etc/os-release"

[ -d "$TARGET_DIR/home" ] || mkdir -p "$TARGET_DIR/home"
chmod 0755 "$TARGET_DIR/home"

# mesa 26 puts the megadriver libgallium in /usr/lib, but EGL/GBM look for it
# in /usr/lib/dri; link it there so the GL renderer can be created.
if [ -d "$TARGET_DIR/usr/lib" ]; then
	mkdir -p "$TARGET_DIR/usr/lib/dri"
	for _g in "$TARGET_DIR"/usr/lib/libgallium-*.so; do
		[ -e "$_g" ] || continue
		ln -sfn "../${_g##*/}" "$TARGET_DIR/usr/lib/dri/${_g##*/}"
	done
fi

# C development files (headers, start files, static libc) so that tcc can
# compile and link programs on the target itself.
STAGING_DIR="$(dirname "$TARGET_DIR")/staging"
if [ -d "$STAGING_DIR/usr/include" ]; then
	mkdir -p "$TARGET_DIR/usr/include"
	cp -a "$STAGING_DIR/usr/include/." "$TARGET_DIR/usr/include/"
fi
for _f in crt1.o crti.o crtn.o Scrt1.o rcrt1.o libc.a libm.a libpthread.a; do
	if [ -f "$STAGING_DIR/usr/lib/$_f" ]; then
		cp -a "$STAGING_DIR/usr/lib/$_f" "$TARGET_DIR/usr/lib/"
	fi
done

# tcc's runtime support library (the *.a cleanup in target-finalize removed it)
for _a in "$(dirname "$TARGET_DIR")"/build/tcc-*/libtcc1.a; do
	[ -f "$_a" ] || continue
	mkdir -p "$TARGET_DIR/usr/lib/tcc"
	cp -f "$_a" "$TARGET_DIR/usr/lib/tcc/libtcc1.a"
done

# buildroot deliberately deletes the cmake/cpack binaries from the target
for _cm in cmake cpack; do
	_src="$(ls -d "$(dirname "$TARGET_DIR")"/build/cmake-*/bin/$_cm 2>/dev/null | head -n1)"
	[ -n "$_src" ] &&
		install -D -m 0755 "$_src" "$TARGET_DIR/usr/bin/$_cm" || true
done

# buildroot installs only a reduced set of cmake modules; copy the full set
_cmbuild="$(ls -d "$(dirname "$TARGET_DIR")"/build/cmake-*/ 2>/dev/null | head -n1)"
_cmshare="$(ls -d "$TARGET_DIR"/usr/share/cmake-*/ 2>/dev/null | head -n1)"
if [ -n "$_cmbuild" ] && [ -n "$_cmshare" ]; then
	for _d in Modules Templates; do
		[ -d "$_cmbuild/$_d" ] &&
			cp -a "$_cmbuild/$_d/." "$_cmshare/$_d/" || true
	done
fi

exit 0
