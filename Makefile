.PHONY: xcodeproj

xcodeproj:
	swift package generate-xcodeproj --xcconfig-overrides=NewtonKit.xcconfig
