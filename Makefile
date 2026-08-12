TARGET = iphone:clang:latest:13.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FeishuAutoStatus

FeishuAutoStatus_FILES = Tweak.x
FeishuAutoStatus_CFLAGS = -fobjc-arc -Wno-arc-performSelector-leaks
FeishuAutoStatus_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Lark || true"
