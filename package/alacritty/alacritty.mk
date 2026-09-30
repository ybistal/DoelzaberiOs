ALACRITTY_VERSION = 0.17.0
ALACRITTY_SITE = $(call github,alacritty,alacritty,v$(ALACRITTY_VERSION))
ALACRITTY_LICENSE = Apache-2.0
ALACRITTY_LICENSE_FILES = LICENSE-APACHE
ALACRITTY_DEPENDENCIES = freetype fontconfig libxkbcommon wayland

ALACRITTY_CARGO_BUILD_OPTS = \
	--no-default-features \
	--features wayland \
	-p alacritty

ALACRITTY_CARGO_ENV = \
	RUSTFLAGS="-C target-feature=-crt-static"

define ALACRITTY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/alacritty \
		$(TARGET_DIR)/usr/bin/alacritty
	$(INSTALL) -D -m 0644 $(@D)/extra/linux/org.alacritty.Alacritty.appdata.xml \
		$(TARGET_DIR)/usr/share/metainfo/org.alacritty.Alacritty.appdata.xml
	$(INSTALL) -D -m 0644 $(@D)/extra/logo/alacritty-term.svg \
		$(TARGET_DIR)/usr/share/icons/hicolor/scalable/apps/Alacritty.svg
endef

$(eval $(cargo-package))
