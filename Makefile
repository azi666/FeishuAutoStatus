ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FeishuAutoStatus

FeishuAutoStatus_FILES = Tweak.x
FeishuAutoStatus_CFLAGS = -fobjc-arc
FeishuAutoStatus_FRAMEWORKS = UIKit Foundation
FeishuAutoStatus_PRIVATE_FRAMEWORKS = BackBoardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 com.ss.iphone.lark"
