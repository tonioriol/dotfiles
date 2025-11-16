 #!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]:-$0}")";

git pull origin master;

function doIt() {
	# ============================================================================
	# Phase 1: Prerequisites
	# ============================================================================
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
	
	# ============================================================================
	# Phase 2: File Synchronization
	# ============================================================================
	echo ""
	echo "=============================================================================="
	echo "Syncing dotfiles to home directory..."
	echo "=============================================================================="
	
	# Sync main dotfiles (excluding special files and non-dotfiles)
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".macos" \
		--exclude "bootstrap.sh" \
		--exclude "tools.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		--exclude "AGENTS.md" \
		--exclude "BOOTSTRAP_REFACTOR_DESIGN.md" \
		--exclude "scripts/" \
		--exclude "Brewfile" \
		--exclude "devbox.json" \
		--exclude ".extra.template" \
		--exclude ".gitignore_global" \
		-avh --no-perms . ~;
	
	# Sync special files with destination mapping
	rsync -avh --no-perms .gitignore_global ~/.gitignore;
	mkdir -p ~/.local/share/devbox/global/default
	rsync -avh --no-perms devbox.json ~/.local/share/devbox/global/default/
	
	echo "✓ Dotfiles synced successfully"
	
	# Source shell configuration
	source ~/.zshrc;
	
	# ============================================================================
	# Phase 3: Environment Setup
	# ============================================================================
	echo ""
	echo "=============================================================================="
	echo "Setting up development environment..."
	echo "=============================================================================="
	
	# Allow direnv for the dotfiles directory if direnv is available
	if command -v direnv &> /dev/null; then
		echo "Approving direnv configuration..."
		direnv allow .
		echo "✓ direnv configuration approved"
	fi
	
	echo "✓ Development environment configured"
	
	# ============================================================================
	# Phase 4: Tool Installation
	# ============================================================================
	echo ""
	echo "=============================================================================="
	echo "Installing development tools..."
	echo "=============================================================================="
	./tools.sh
	
	# ============================================================================
	# Phase 5: Secrets & Configuration
	# ============================================================================
	# Restore secrets if .secrets directory exists
	if [ -d ".secrets" ]; then
		echo ""
		echo "=============================================================================="
		echo "Restoring secrets..."
		echo "=============================================================================="
		./scripts/secrets.sh restore
	fi
	
	# Run .macos to configure macOS settings
	echo ""
	echo "=============================================================================="
	echo "Configuring macOS settings..."
	echo "=============================================================================="
	./.macos
	
	# ============================================================================
	# Phase 6: Completion
	# ============================================================================
	echo ""
	echo "=============================================================================="
	echo "✓ Bootstrap complete!"
	echo "=============================================================================="
	echo "Your dotfiles have been installed and configured."
	echo ""
	echo "Next steps:"
	echo "  1. Restart your computer for all macOS settings to take effect"
	echo "  2. If GPG keys were restored, add the key ID to ~/.extra and source it"
	echo "=============================================================================="
}

if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " REPLY
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
