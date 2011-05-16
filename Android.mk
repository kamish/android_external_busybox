LOCAL_PATH := $(call my-dir)

# Make a static library for clearsilver's regex. This prevents multiple
# symbol definition error.
include $(CLEAR_VARS)
LOCAL_SRC_FILES := ../clearsilver/util/regex/regex.c
LOCAL_MODULE := libclearsilverregex
LOCAL_C_INCLUDES := \
	external/clearsilver \
	external/clearsilver/util/regex
include $(BUILD_STATIC_LIBRARY)


SUBMAKE := make -s -C $(LOCAL_PATH) CC=$(CC)
KERNEL_MODULES_DIR?=/system/modules/lib/modules

BUSYBOX_SRC_FILES = $(shell cat $(LOCAL_PATH)/busybox-$(BUSYBOX_CONFIG).sources) \
	libbb/android.c

BUSYBOX_C_INCLUDES = \
	$(LOCAL_PATH)/include-$(BUSYBOX_CONFIG) \
	$(LOCAL_PATH)/include $(LOCAL_PATH)/libbb \
	external/clearsilver \
	external/clearsilver/util/regex \
	bionic/libc/private \
	libc/kernel/common

BUSYBOX_CFLAGS = \
	-std=gnu99 \
	-Werror=implicit \
	-Wno-format \
	-DNDEBUG \
	-DANDROID_CHANGES \
	-include include-$(BUSYBOX_CONFIG)/autoconf.h \
	-D'CONFIG_DEFAULT_MODULES_DIR="$(KERNEL_MODULES_DIR)"' \
	-D'BB_VER="$(strip $(shell $(SUBMAKE) kernelversion))$(BUSYBOX_CONFIG)"' -DBB_BT=AUTOCONF_TIMESTAMP


include $(CLEAR_VARS)
BUSYBOX_CONFIG:=full
LOCAL_SRC_FILES := $(BUSYBOX_SRC_FILES)
LOCAL_C_INCLUDES := $(BUSYBOX_C_INCLUDES)
LOCAL_CFLAGS := $(BUSYBOX_CFLAGS)
LOCAL_MODULE := busybox
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT_OPTIONAL_EXECUTABLES)
LOCAL_STATIC_LIBRARIES += libclearsilverregex
include $(BUILD_EXECUTABLE)

BUSYBOX_LINKS := $(shell cat $(LOCAL_PATH)/busybox-$(BUSYBOX_CONFIG).links)
# nc is provided by external/netcat
exclude := nc
SYMLINKS := $(addprefix $(TARGET_OUT_OPTIONAL_EXECUTABLES)/,$(filter-out $(exclude),$(notdir $(BUSYBOX_LINKS))))
$(SYMLINKS): BUSYBOX_BINARY := $(LOCAL_MODULE)
$(SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "Symlink: $@ -> $(BUSYBOX_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf $(BUSYBOX_BINARY) $@

ALL_DEFAULT_INSTALLED_MODULES += $(SYMLINKS)

# We need this so that the installed files could be picked up based on the
# local module name
ALL_MODULES.$(LOCAL_MODULE).INSTALLED := \
    $(ALL_MODULES.$(LOCAL_MODULE).INSTALLED) $(SYMLINKS)


# Build a static busybox for the recovery image
include $(CLEAR_VARS)
BUSYBOX_CONFIG:=minimal
LOCAL_SRC_FILES := $(BUSYBOX_SRC_FILES)
LOCAL_C_INCLUDES := $(BUSYBOX_C_INCLUDES)
LOCAL_CFLAGS := -Dmain=busybox_driver $(BUSYBOX_CFLAGS)
LOCAL_CFLAGS += \
  -Dgetmntent=busybox_getmntent \
  -Dgetmntent_r=busybox_getmntent_r
LOCAL_MODULE := libbusybox
LOCAL_STATIC_LIBRARIES += libclearsilverregex libcutils libc libm 
include $(BUILD_STATIC_LIBRARY)
