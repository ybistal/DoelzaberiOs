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

for _script in usr/bin/doelzaberi-gui etc/init.d/doelzaberi-runtime; do
	[ -e "$TARGET_DIR/$_script" ] &&
		chmod 0755 "$TARGET_DIR/$_script" || true
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

exit 0
