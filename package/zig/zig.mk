ZIG_VERSION = 0.16.0
ZIG_SOURCE = ziglang-$(ZIG_VERSION)-py3-none-manylinux_2_12_x86_64.manylinux2010_x86_64.musllinux_1_1_x86_64.whl
ZIG_SITE = https://files.pythonhosted.org/packages/3e/ed/7b79023aa27ceb5d461ecf761181e7c33c57bbc1a6256a39535d1c7083d2
ZIG_LICENSE = MIT
ZIG_LICENSE_FILES = ziglang/LICENSE
ZIG_EXTRACT_DEPENDENCIES = host-python3

define ZIG_EXTRACT_CMDS
	$(HOST_DIR)/bin/python3 -m zipfile -e $(ZIG_DL_DIR)/$(ZIG_SOURCE) $(@D)
endef

define ZIG_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/ziglang/zig $(TARGET_DIR)/usr/lib/zig/zig
	cp -a $(@D)/ziglang/lib $(TARGET_DIR)/usr/lib/zig/lib
	ln -sfn ../lib/zig/zig $(TARGET_DIR)/usr/bin/zig
	for _w in cc gcc c++ g++; do \
		$(INSTALL) -D -m 0755 $(ZIG_PKGDIR)/$$_w $(TARGET_DIR)/usr/bin/$$_w; \
	done
endef

$(eval $(generic-package))
