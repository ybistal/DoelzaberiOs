HYPRLAND_VERSION = 0.48.1
HYPRLAND_SITE = $(call github,hyprwm,Hyprland,v$(HYPRLAND_VERSION))
HYPRLAND_LICENSE = BSD-3-Clause
HYPRLAND_LICENSE_FILES = LICENSE
HYPRLAND_DEPENDENCIES = aquamarine cairo hyprcursor hyprgraphics hyprland-protocols \
	hyprlang hyprutils libdisplay-info libdrm libinput libxkbcommon mesa3d pango \
	pixman re2 seatd util-linux udis86 wayland wayland-protocols xlib_libXcursor

HYPRLAND_CONF_OPTS = \
	-DNO_HYPRPM=ON \
	-DNO_SYSTEMD=ON \
	-DNO_XWAYLAND=ON \
	-Dhyprwayland-scanner_DIR=$(HOST_DIR)/lib/cmake/hyprwayland-scanner \
	-DOPENGL_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DOPENGL_EGL_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DOPENGL_GLES2_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DOPENGL_GLES3_INCLUDE_DIR=$(STAGING_DIR)/usr/include \
	-DOPENGL_opengl_LIBRARY=$(STAGING_DIR)/usr/lib/libGLESv2.so \
	-DOPENGL_gl_LIBRARY=$(STAGING_DIR)/usr/lib/libGLESv2.so \
	-DOPENGL_egl_LIBRARY=$(STAGING_DIR)/usr/lib/libEGL.so \
	-DOPENGL_gles2_LIBRARY=$(STAGING_DIR)/usr/lib/libGLESv2.so \
	-DOPENGL_gles3_LIBRARY=$(STAGING_DIR)/usr/lib/libGLESv2.so \
	-DCMAKE_EXE_LINKER_FLAGS="$(TARGET_LDFLAGS) -Wl,--allow-shlib-undefined"

HYPRLAND_CXXFLAGS = $(TARGET_CXXFLAGS) -Wno-error

$(eval $(cmake-package))
