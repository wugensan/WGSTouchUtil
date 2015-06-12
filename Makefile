THEOS_DEVICE_IP = 192.168.2.41
ARCHS = armv7s arm64
TARGET = iphone:7.0:6.1
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

TWEAK_NAME = CNSimulateTouch
CNSimulateTouch_FILES = CNSimulateTouch.mm
CNSimulateTouch_FRAMEWORKS = Foundation QuartzCore
CNSimulateTouch_PRIVATE_FRAMEWORKS = GraphicsServices IOKit AppSupport
CNSimulateTouch_LDFLAGS = -lsubstrate -lrocketbootstrap

LIBRARY_NAME = libcnsimulatetouch
libcnsimulatetouch_FILES = CNSTLibrary.mm
libcnsimulatetouch_LDFLAGS = -lrocketbootstrap
libcnsimulatetouch_INSTALL_PATH = /usr/lib/
libcnsimulatetouch_FRAMEWORKS = UIKit CoreGraphics Foundation
libcnsimulatetouch_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/library.mk

after-install::
	install.exec "killall -9 backboardd;"
