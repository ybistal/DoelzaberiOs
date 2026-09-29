
FISH_VERSION = 3.7.1
FISH_SOURCE = fish-$(FISH_VERSION).tar.xz
FISH_SITE = https://github.com/fish-shell/fish-shell/releases/download/$(FISH_VERSION)
FISH_LICENSE = GPL-2.0-only
FISH_LICENSE_FILES = COPYING
FISH_DEPENDENCIES = host-pkgconf ncurses pcre2
FISH_CONF_OPTS = \
	-DFISH_USE_SYSTEM_PCRE2=ON \
	-DWITH_GETTEXT=OFF \
	-DBUILD_DOCS=OFF \
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5

$(eval $(cmake-package))
