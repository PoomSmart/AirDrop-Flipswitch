GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

BUNDLE_NAME = AirDropToggle
AirDropToggle_FILES = Switch.xm
AirDropToggle_FRAMEWORKS = UIKit
AirDropToggle_PRIVATE_FRAMEWORKS = Sharing
AirDropToggle_LIBRARIES = flipswitch substrate
AirDropToggle_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk
