#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]:-$0}")";

git pull origin master;

function doIt() {
	# Check if .extra exists before proceeding
	if [ ! -f ~/.extra ] && [ ! -f .extra ]; then
		echo "❌ Error: .extra file not found!"
		echo ""
		echo "Please create ~/.extra from .extra.template first:"
		echo "  cp .extra.template ~/.extra"
		echo "  vim ~/.extra  # Edit with your personal information"
		echo ""
		return 1
	fi
	
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "brew.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		--exclude "AGENTS.md" \
		--exclude "scripts/" \
		-avh --no-perms . ~;
	source ~/.zshrc;
	
	# Copy devbox global configuration to proper location
	if [ -f devbox.json ]; then
		echo ""
		echo "Setting up devbox global configuration..."
		mkdir -p ~/.local/share/devbox/global/default
		cp devbox.json ~/.local/share/devbox/global/default/devbox.json
		echo "✓ Devbox configuration copied to ~/.local/share/devbox/global/default/devbox.json"
	fi
	
	# Run brew.sh to install packages
	echo ""
	echo "=============================================================================="
	echo "Running brew.sh to install packages..."
	echo "=============================================================================="
	./brew.sh
	
	# Run .macos to configure macOS settings
	# echo ""
	# echo "=============================================================================="
	# echo "Running .macos to configure macOS settings..."
	# echo "=============================================================================="
	# ./.macos  # Disabled: currently broken
	
	echo ""
	echo "=============================================================================="
	echo "✓ Bootstrap complete!"
	echo "=============================================================================="
	echo "Your dotfiles have been installed and configured."
	echo ""
	echo "Next steps:"
	echo "  1. Restart your computer for all macOS settings to take effect"
	echo "  2. Restore secrets if needed: ./scripts/secrets.sh restore"
	echo "  3. If you restored GPG keys, add the key ID to ~/.extra and source it"
	echo "=============================================================================="
}

if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
	doIt;
else
	read "REPLY?This may overwrite existing files in your home directory. Are you sure? (y/n) ";
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
