THEOS_PACKAGE_SCHEME = rootless
TARGET              := iphone:clang:latest:15.0
ARCHS               = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoSpotifyLyrics

NoSpotifyLyrics_FILES    = Tweak.x
NoSpotifyLyrics_CFLAGS   = -fobjc-arc
NoSpotifyLyrics_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
