.PHONY: all generate build test run clean check-widget register-widget

PROJECT_NAME = GitStreak
SCHEME = GitStreak
CONFIG = Debug
BUILD_DIR = ./build

all: generate build

# Generate Xcode project from project.yml
generate:
	xcodegen generate

# Build the app, framework, and widget extension with Apple Development signing
build:
	xcodebuild build \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-derivedDataPath $(BUILD_DIR) \
		-allowProvisioningUpdates

# Run unit tests
test:
	xcodebuild test \
		-project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-derivedDataPath $(BUILD_DIR) \
		-destination 'platform=macOS' \
		-allowProvisioningUpdates

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

# Clean all build artifacts
clean:
	rm -rf $(BUILD_DIR) $(PROJECT_NAME).xcodeproj
