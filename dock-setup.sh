#!/bin/bash

# Dock Configuration Script
# Configures macOS Dock apps, spacers, and settings

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCK_APPS_FILE="${SCRIPT_DIR}/dock-apps.txt"

echo "🎯 Configuring Dock..."
echo ""

# Check if dock-apps.txt exists
if [[ ! -f "$DOCK_APPS_FILE" ]]; then
    echo "❌ Error: dock-apps.txt not found at $DOCK_APPS_FILE"
    exit 1
fi

# Function to find app path
find_app() {
    local app_name="$1"
    local app_path=""

    # Try exact match in common locations
    for location in "/Applications" "/System/Applications" "/Applications/Utilities" "/System/Applications/Utilities" "$HOME/Applications"; do
        if [[ -d "${location}/${app_name}.app" ]]; then
            echo "${location}/${app_name}.app"
            return 0
        fi
    done

    # Try in subdirectories (e.g., Adobe apps: /Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app)
    for location in "/Applications" "$HOME/Applications"; do
        if [[ -d "${location}/${app_name}/${app_name}.app" ]]; then
            echo "${location}/${app_name}/${app_name}.app"
            return 0
        fi
    done

    # Try to find app in subdirectories (for apps like Adobe Illustrator.app in Adobe Illustrator 2025/)
    for location in "/Applications" "$HOME/Applications"; do
        app_path=$(find "$location" -maxdepth 2 -name "${app_name}.app" -type d 2>/dev/null | head -1)
        if [[ -n "$app_path" ]] && [[ -d "$app_path" ]]; then
            echo "$app_path"
            return 0
        fi
    done

    # Try with mdfind (Spotlight)
    app_path=$(mdfind "kMDItemKind == 'Application' && kMDItemFSName == '${app_name}.app'" 2>/dev/null | head -1)
    if [[ -n "$app_path" ]] && [[ -d "$app_path" ]]; then
        echo "$app_path"
        return 0
    fi

    return 1
}

# Clear existing Dock
echo "→ Clearing existing Dock..."
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock persistent-others -array

# Read dock-apps.txt and build Dock
echo "→ Adding apps from dock-apps.txt..."
echo ""

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    # Remove leading/trailing whitespace
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$line" ]] && continue

    # Check for spacer
    if [[ "$line" == "---" ]]; then
        echo "   ✓ Adding small spacer"
        defaults write com.apple.dock persistent-apps -array-add '{tile-type="small-spacer-tile";}'
        continue
    fi

    # Check for folder
    if [[ "$line" =~ ^folder:(.+)$ ]]; then
        folder_path="${BASH_REMATCH[1]}"
        # Expand tilde
        folder_path="${folder_path/#\~/$HOME}"

        if [[ -d "$folder_path" ]]; then
            folder_name=$(basename "$folder_path")
            echo "   ✓ Adding folder: ${folder_name}"
            defaults write com.apple.dock persistent-others -array-add "<dict>
                <key>tile-data</key>
                <dict>
                    <key>file-data</key>
                    <dict>
                        <key>_CFURLString</key>
                        <string>file://${folder_path}/</string>
                        <key>_CFURLStringType</key>
                        <integer>15</integer>
                    </dict>
                    <key>file-label</key>
                    <string>${folder_name}</string>
                    <key>file-type</key>
                    <integer>2</integer>
                </dict>
                <key>tile-type</key>
                <string>directory-tile</string>
            </dict>"
        else
            echo "   ⚠️  Warning: Folder not found - $folder_path"
        fi
        continue
    fi

    # Regular app
    app_path=$(find_app "$line")
    if [[ $? -eq 0 ]] && [[ -n "$app_path" ]]; then
        echo "   ✓ Adding: $line"
        defaults write com.apple.dock persistent-apps -array-add "<dict>
            <key>tile-data</key>
            <dict>
                <key>file-data</key>
                <dict>
                    <key>_CFURLString</key>
                    <string>file://${app_path}/</string>
                    <key>_CFURLStringType</key>
                    <integer>15</integer>
                </dict>
                <key>file-label</key>
                <string>${line}</string>
                <key>file-type</key>
                <integer>41</integer>
            </dict>
            <key>tile-type</key>
            <string>file-tile</string>
        </dict>"
    else
        echo "   ⚠️  Warning: App not found - $line"
    fi

done < "$DOCK_APPS_FILE"

echo ""
echo "→ Configuring Dock settings..."

# Dock Settings
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock size-immutable -bool false
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 64
defaults write com.apple.dock orientation -string "bottom"
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string "genie"
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock launchanim -bool true

echo "   ✓ Dock preferences configured"

# Restart Dock
echo ""
echo "→ Restarting Dock..."
killall Dock

echo ""
echo "✅ Dock configuration complete!"
echo ""
echo "📝 To modify your Dock setup:"
echo "   1. Edit: dock-apps.txt"
echo "   2. Run: ./dock-setup.sh"
