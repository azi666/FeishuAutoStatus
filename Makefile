TARGET = iphone:clang:latest:13.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FeishuAutoStatus

FeishuAutoStatus_FILES = Tweak.x SettingsViewController.m
FeishuAutoStatus_CFLAGS = -fobjc-arc -Wno-arc-performSelector-leaks
FeishuAutoStatus_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

# BUNDLE_NAME = FeishuAutoStatusPrefs
# 
# FeishuAutoStatusPrefs_FILES = feishuautostatusprefs/FeishuAutoStatusPrefs.m
# FeishuAutoStatusPrefs_INSTALL_PATH = /Library/PreferenceBundles
# FeishuAutoStatusPrefs_FRAMEWORKS = UIKit
# FeishuAutoStatusPrefs_PRIVATE_FRAMEWORKS = Preferences
# FeishuAutoStatusPrefs_CFLAGS = -fobjc-arc
# FeishuAutoStatusPrefs_RESOURCE_DIRS = feishuautostatusprefs/Resources
# 
# include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 Lark || true"
