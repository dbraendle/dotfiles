#!/usr/bin/env bash
# Setup Sublime Text settings from dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBLIME_USER_DIR="${HOME}/Library/Application Support/Sublime Text/Packages/User"
SUBLIME_SETTINGS="${SUBLIME_USER_DIR}/Preferences.sublime-settings"
DOTFILES_SUBLIME="${DOTFILES_DIR}/config/sublime/Preferences.sublime-settings"

echo "🔧 Setting up Sublime Text settings..."

# Check if Sublime is installed
if [ ! -d "${SUBLIME_USER_DIR}" ]; then
    echo "⚠️  Sublime Text not installed, skipping..."
    exit 0
fi

# Backup existing settings
if [ -f "${SUBLIME_SETTINGS}" ] && [ ! -L "${SUBLIME_SETTINGS}" ]; then
    echo "📦 Backing up existing settings..."
    mv "${SUBLIME_SETTINGS}" "${SUBLIME_SETTINGS}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Remove existing file/symlink
rm -f "${SUBLIME_SETTINGS}"

# Create symlink
echo "🔗 Creating symlink..."
ln -s "${DOTFILES_SUBLIME}" "${SUBLIME_SETTINGS}"

echo "✅ Sublime Text settings linked!"
echo "   ${SUBLIME_SETTINGS} -> ${DOTFILES_SUBLIME}"
