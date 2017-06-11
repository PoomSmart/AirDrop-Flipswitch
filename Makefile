DEBUG = 0
PACKAGE_VERSION = 0.0.2

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = AirDropToggle
AirDropToggle_FILES = Settings.m Switch.xm
AirDropToggle_FRAMEWORKS = UIKit
AirDropToggle_PRIVATE_FRAMEWORKS = Sharing
AirDropToggle_LIBRARIES = flipswitch substrate
AirDropToggle_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk
