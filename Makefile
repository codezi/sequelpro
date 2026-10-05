CONFIG=Debug
OPTIONS=

BUILD_CONFIG?=$(CONFIG)

CP=ditto --rsrc
RM=rm

.PHONY: sequel-pro test analyze clean localize

sequel-pro:
	xcodebuild -project sequel-pro.xcodeproj -scheme "Sequel Pro" -configuration "$(BUILD_CONFIG)" CFLAGS="$(SP_CFLAGS)" $(OPTIONS) build

test:
	xcodebuild -project sequel-pro.xcodeproj -scheme "Sequel Pro" -configuration "$(BUILD_CONFIG)" CFLAGS="$(SP_CFLAGS)" $(OPTIONS) test

analyze:
	xcodebuild -project sequel-pro.xcodeproj -scheme "Sequel Pro" -configuration "$(BUILD_CONFIG)" CFLAGS="$(SP_CFLAGS)" $(OPTIONS) analyze

clean:
	xcodebuild -project sequel-pro.xcodeproj -scheme "Sequel Pro" -configuration "$(BUILD_CONFIG)" $(OPTIONS) clean

localize:
	xcodebuild -project sequel-pro.xcodeproj -scheme "Localize" -configuration "$(BUILD_CONFIG)" $(OPTIONS)

# Native Apple Silicon build. Products and logs stay inside the checkout.
NATIVE_CONFIG?=Release
NATIVE_DERIVED_DATA?=$(CURDIR)/.build/DerivedData

.PHONY: native native-test verify-native
native:
	xcodebuild -project sequel-pro.xcodeproj -scheme "Sequel Pro" -configuration "$(NATIVE_CONFIG)" -destination 'platform=macOS,arch=arm64' -derivedDataPath "$(NATIVE_DERIVED_DATA)" ARCHS=arm64 ONLY_ACTIVE_ARCH=YES $(OPTIONS) build
	"$(CURDIR)/Scripts/verify-native.sh" "$(NATIVE_DERIVED_DATA)/Build/Products/$(NATIVE_CONFIG)/Sequel Pro.app"

native-test:
	xcodebuild -project sequel-pro.xcodeproj -scheme "Sequel Pro" -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath "$(NATIVE_DERIVED_DATA)" ARCHS=arm64 ONLY_ACTIVE_ARCH=YES $(OPTIONS) test
	"$(CURDIR)/Frameworks/NativeBuild/smoke-test.sh"
	"$(CURDIR)/Frameworks/NativeBuild/tracking-smoke.sh" "$(NATIVE_DERIVED_DATA)/Build/Products/Debug"

verify-native:
	"$(CURDIR)/Scripts/verify-native.sh" "$(NATIVE_DERIVED_DATA)/Build/Products/$(NATIVE_CONFIG)/Sequel Pro.app"
