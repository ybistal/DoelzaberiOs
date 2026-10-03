################################################################################
#
# tcc
#
################################################################################

TCC_VERSION = 0.9.27
TCC_SOURCE = tcc-$(TCC_VERSION).tar.bz2
TCC_SITE = https://download.savannah.gnu.org/releases/tinycc
TCC_LICENSE = LGPL-2.1
TCC_LICENSE_FILES = COPYING

define TCC_CONFIGURE_CMDS
	(cd $(@D); \
		./configure --prefix=/usr --cpu=x86_64 \
			--cc="$(TARGET_CC)" --ar="$(TARGET_AR)" \
			--extra-cflags="$(TARGET_CFLAGS)" \
			--extra-ldflags="$(TARGET_LDFLAGS)" \
			--config-musl --config-bcheck=no --config-backtrace=no)
endef

define TCC_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		CC="$(TARGET_CC)" AR="$(TARGET_AR)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		x86_64-libtcc1-usegcc=yes
endef

define TCC_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) install DESTDIR=$(TARGET_DIR)
	$(INSTALL) -D -m 0644 $(@D)/libtcc1.a \
		$(TARGET_DIR)/usr/lib/tcc/libtcc1.a
endef

$(eval $(generic-package))
