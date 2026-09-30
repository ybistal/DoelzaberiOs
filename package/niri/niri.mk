NIRI_VERSION = 26.04
NIRI_SITE = $(call github,YaLTeR,niri,v$(NIRI_VERSION))
NIRI_LICENSE = GPL-3.0-only
NIRI_LICENSE_FILES = LICENSE
NIRI_DEPENDENCIES = dbus fontconfig freetype libdisplay-info libdrm libinput \
	libxkbcommon pango wayland

NIRI_CARGO_BUILD_OPTS = \
	--no-default-features \
	--features dbus

NIRI_CARGO_ENV = \
	RUSTFLAGS="-C target-feature=-crt-static"

define NIRI_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/niri \
		$(TARGET_DIR)/usr/bin/niri
	$(INSTALL) -D -m 0644 $(@D)/resources/niri.desktop \
		$(TARGET_DIR)/usr/share/wayland-sessions/niri.desktop
	$(INSTALL) -D -m 0644 $(@D)/resources/niri-portals.conf \
		$(TARGET_DIR)/usr/share/xdg-desktop-portal/niri-portals.conf
	$(INSTALL) -D -m 0755 $(@D)/resources/niri-session \
		$(TARGET_DIR)/usr/bin/niri-session
endef

$(eval $(cargo-package))
