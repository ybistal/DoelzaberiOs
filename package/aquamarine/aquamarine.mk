AQUAMARINE_VERSION = 0.9.5
AQUAMARINE_SITE = $(call github,hyprwm,aquamarine,v$(AQUAMARINE_VERSION))
AQUAMARINE_LICENSE = BSD-3-Clause
AQUAMARINE_LICENSE_FILES = LICENSE
AQUAMARINE_DEPENDENCIES = host-hyprwayland-scanner hyprutils hwdata libdisplay-info \
	libdrm libinput libxkbcommon mesa3d pixman seatd wayland wayland-protocols

AQUAMARINE_INSTALL_STAGING = YES

AQUAMARINE_CONF_OPTS = \
	-Dhyprwayland-scanner_DIR=$(HOST_DIR)/lib/cmake/hyprwayland-scanner \
	-DOPENGL_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DOPENGL_EGL_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DOPENGL_GLES3_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DOPENGL_opengl_LIBRARY=$(STAGING_DIR)/usr/lib/libGLESv2.so \
	-DOPENGL_egl_LIBRARY=$(STAGING_DIR)/usr/lib/libEGL.so \
	-DOPENGL_gles3_LIBRARY=$(STAGING_DIR)/usr/lib/libGLESv2.so

$(eval $(cmake-package))
