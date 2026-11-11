.PHONY: all generate build test run clean check-widget register-widget unregister-build-copies release dmg

PROJECT_NAME = GitStreak
SCHEME = GitStreak
CONFIG = Debug
BUILD_DIR = ./build
LSREGISTER = /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
WIDGET_ID = com.gitstreak.GitStreak.Widget

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
	@$(MAKE) --no-print-directory unregister-build-copies

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
	@$(MAKE) --no-print-directory unregister-build-copies

# Copies of the app in ./build share the widget's bundle ID with the installed app.
# If macOS knows about several copies, desktop widgets vanish whenever one changes,
# so only the copy in /Applications should stay registered.
unregister-build-copies:
	@for c in Debug Release; do \
		app="$(BUILD_DIR)/Build/Products/$$c/$(PROJECT_NAME).app"; \
		if [ -d "$$app" ]; then \
			pluginkit -r "$$app/Contents/PlugIns/$(PROJECT_NAME)WidgetExtension.appex" 2>/dev/null; \
			$(LSREGISTER) -u "$$app" 2>/dev/null; \
		fi; \
	done; true

# Install to /Applications and register the widget extension with LaunchServices & PluginKit
register-widget: build
	# Update in place, so the installed app's path never disappears
	rsync -a --delete $(BUILD_DIR)/Build/Products/$(CONFIG)/$(PROJECT_NAME).app/ /Applications/$(PROJECT_NAME).app/
	$(LSREGISTER) -f -R -trusted /Applications/$(PROJECT_NAME).app
	pluginkit -a /Applications/$(PROJECT_NAME).app/Contents/PlugIns/$(PROJECT_NAME)WidgetExtension.appex 2>/dev/null || true
	pluginkit -e use -i $(WIDGET_ID) 2>/dev/null || true
	killall NotificationCenter 2>/dev/null || true

# Run the compiled macOS app
run: register-widget
	open /Applications/$(PROJECT_NAME).app

# Check if the widget is registered (only /Applications should be listed)
check-widget:
	pluginkit -m -A -D -v -p com.apple.widgetkit-extension 2>/dev/null | grep -i $(PROJECT_NAME) || echo "Widget check completed."

# Package DMG installer and Sparkle ZIP release artifacts
release:
	./scripts/package_release.sh
	@$(MAKE) --no-print-directory unregister-build-copies CONFIG=Release

dmg: release

# Clean all build artifacts
clean: unregister-build-copies
	rm -rf $(BUILD_DIR) $(PROJECT_NAME).xcodeproj
