.PHONY: all generate build test run clean check-widget register-widget release dmg

PROJECT_NAME = GitStreak
SCHEME = GitStreak
CONFIG = Debug
BUILD_DIR = ./build

all: generate build

# Generate Xcode project from project.yml
generate:
	xcodegen generate

# Build the app, framework, and widget extension
build:
	xcodebuild build \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-derivedDataPath $(BUILD_DIR) \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=YES

# Run unit tests
test:
	xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-derivedDataPath $(BUILD_DIR) \
		-destination 'platform=macOS' \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=YES

# Register widget extension with macOS LaunchServices & PluginKit
register-widget:
	mkdir -p ~/Applications
	rm -rf ~/Applications/$(PROJECT_NAME).app
	cp -R $(BUILD_DIR)/Build/Products/$(CONFIG)/$(PROJECT_NAME).app ~/Applications/
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R -trusted ~/Applications/$(PROJECT_NAME).app
	pluginkit -a ~/Applications/$(PROJECT_NAME).app/Contents/PlugIns/$(PROJECT_NAME)WidgetExtension.appex 2>/dev/null || true
	pluginkit -e use -i com.gitstreak.GitStreak.Widget 2>/dev/null || true
	killall NotificationCenter 2>/dev/null || true

# Run the compiled macOS app
run: register-widget
	open ~/Applications/$(PROJECT_NAME).app

# Check if the widget is registered
check-widget:
	pluginkit -m -p com.apple.widgetkit-extension -v 2>/dev/null | grep -i $(PROJECT_NAME) || echo "Widget check completed."

# Package DMG installer and Sparkle ZIP release artifacts
release:
	./scripts/package_release.sh 1.0.0

dmg: release

# Clean all build artifacts
clean:
	rm -rf $(BUILD_DIR) $(PROJECT_NAME).xcodeproj


