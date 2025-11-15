#!/usr/bin/env bash
# Comprehensive brew.sh — includes all formulae/casks from upstream dotfiles + your machine.
# Each entry is documented with its purpose and source (upstream/your-machine).
# Edit this file to remove packages you don't want before running.
#
# Note: --no-quarantine flag is deprecated in Homebrew 5.0.0+ (Nov 2025)
# To bypass macOS Gatekeeper quarantine on installed apps, use:
#   xattr -d com.apple.quarantine /Applications/AppName.app
# Or for all apps: xattr -dr com.apple.quarantine /Applications/*.app
set -euo pipefail

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for current session (Apple Silicon)
    if [[ $(uname -m) == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    if command -v brew &> /dev/null; then
        echo "✓ Homebrew installed successfully"
    else
        echo "❌ Homebrew installation failed. Please install manually:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
else
    echo "✓ Homebrew is already installed"
fi

# Check Homebrew permissions and fix if needed
BREW_PREFIX="$(brew --prefix)"
if [ ! -w "$BREW_PREFIX" ]; then
    echo "⚠ Homebrew directory is not writable. Fixing permissions..."
    echo "This requires sudo access."
    sudo chown -R "$(whoami)" "$BREW_PREFIX"
    echo "✓ Permissions fixed"
fi

echo "Updating Homebrew and upgrading existing packages..."
brew update
brew upgrade

BREW_PREFIX="$(brew --prefix)"

# All packages (formulae and casks merged - Homebrew 4.0+ handles both)
PACKAGES=(
# === macOS-specific CLI tools ===
mas                # App Store CLI: install Mac App Store apps from terminal (yours)
                   # Note: mas is macOS-specific and requires deep system integration with the Mac App Store
                   # All other CLI tools are now managed by devbox (see .devbox-global.json)

# === GUI Applications ===

# === Browsers ===
google-chrome      # Chrome: fast browser, good dev tools (upstream+yours)
firefox            # Firefox: privacy-focused browser, great dev tools (upstream+yours)
microsoft-edge     # Edge: Chromium-based, good for testing (yours)
zen@twilight        # Zen: minimalist browser (yours)

# === Development tools ===
visual-studio-code # VS Code: powerful code editor with extensions (upstream+yours)
warp               # Modern terminal: AI-powered terminal with modern UI (yours)
orbstack           # Fast Docker: faster Docker alternative for Mac, replaces Docker Desktop (yours)
colima             # Lightweight Docker alternative for macOS (Apple Silicon optimized, replaces Docker Desktop)
                   # Container runtime with minimal resource usage, compatible with Docker CLI
                   # See: https://github.com/abiosoft/colima
postman            # API test: test REST APIs with GUI (upstream+yours)
lens               # k8s IDE: visual Kubernetes management (yours)

# === Productivity and utilities ===
1password          # Passwords: secure password manager (upstream+yours)
raycast            # Launcher: Spotlight replacement with plugins (upstream+yours)
barrier            # Share input: share keyboard/mouse across computers (yours)
maccy              # Clipboard manager: modern, lightweight clipboard history (replaces flycut)

# === Media and entertainment ===
spotify            # Music: stream music (upstream+yours)
foobar2000         # Audio player: advanced audio player (yours)
steam              # Gaming: PC game platform (yours)
openemu            # Emulator: play retro console games (yours)
audacity           # Audio edit: record/edit audio (yours)
musicbrainz-picard # Music tag: auto-tag music files (yours)
heroic             # Epic Games: play Epic/GOG games (yours)

# === Communication ===
slack              # Team chat: workplace communication (upstream)

# === System tools and utilities ===
onyx               # Mac maintenance: clean/optimize macOS (yours)
appcleaner         # Uninstaller: completely remove apps (upstream)
keka               # Archives: extract AND create archives with GUI, handles formats macOS can't (RAR, 7z, etc.) (yours)

# === Networking and analysis ===
wireshark          # Wireshark GUI: visual packet analysis (yours)
fing               # Network scan: discover devices on network (yours)
angry-ip-scanner   # IP scanner: fast network scanner (yours)
netspot            # WiFi analyze: WiFi site survey and analysis (yours)

# === Fonts ===
font-monaspace     # Monaspace: modern monospace font family for coding (yours)

# === Remote access ===
teamviewer         # Remote desktop: remote computer access (upstream)

# === Design and content ===
canva              # Design: graphic design tool (yours)

# === Backup and sync ===
rsyncui            # rsync GUI: visual rsync file sync (yours)
transmission       # Torrent: lightweight BitTorrent client (upstream)
)

echo "Installing packages..."

# Build list of package names (filter out comments and empty lines)
TO_INSTALL=()
for pkg in "${PACKAGES[@]}"; do
  # Skip comments and empty lines
  [[ "$pkg" =~ ^#.*$ ]] && continue
  [[ -z "$pkg" ]] && continue
  
  # Extract package name (everything before first space/comment)
  pkg_name=$(echo "$pkg" | awk '{print $1}')
  TO_INSTALL+=("$pkg_name")
done

# Install all packages with --cask flag - brew handles parallelization and skips already installed
if [ ${#TO_INSTALL[@]} -gt 0 ]; then
  echo "Installing ${#TO_INSTALL[@]} packages (brew will parallelize and skip already installed)..."
  brew install --cask "${TO_INSTALL[@]}" || echo "Some packages failed to install"
else
  echo "No packages to install!"
fi

# Add brew-installed bash to /etc/shells if present (do not change user shell automatically)
if [ -x "${BREW_PREFIX}/bin/bash" ] && ! grep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "Adding ${BREW_PREFIX}/bin/bash to /etc/shells (requires sudo)"
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells
fi

echo "Running brew cleanup..."
brew cleanup

echo ""
echo "=============================================================================="
echo "Installing devbox (development environment manager)..."
echo "=============================================================================="

# Check if devbox is already installed
if command -v devbox &> /dev/null; then
    echo "✓ devbox is already installed"
else
    echo "Installing devbox via official installer..."
    curl -fsSL https://get.jetify.com/devbox | bash
    
    # Add devbox to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    
    if command -v devbox &> /dev/null; then
        echo "✓ devbox installed successfully"
    else
        echo "⚠ devbox installation failed. Please install manually:"
        echo "  curl -fsSL https://get.jetify.com/devbox | bash"
        exit 1
    fi
fi

echo ""
echo "=============================================================================="
echo "Setting up devbox global packages..."
echo "=============================================================================="

# Initialize devbox global environment if configuration exists
if [ -f ~/.local/share/devbox/global/default/devbox.json ]; then
    echo "Initializing devbox global environment..."
    # The shellenv will automatically load packages from the config
    eval "$(devbox global shellenv)"
    echo "✓ Devbox global environment initialized"
else
    echo "⚠ Devbox configuration not found at ~/.local/share/devbox/global/default/devbox.json"
    echo "  Run bootstrap.sh first to copy the configuration"
fi

echo ""
echo "Configuration file: ~/.local/share/devbox/global/default/devbox.json"
echo "  - Edit devbox.json in the dotfiles repo, then run bootstrap.sh to sync"
echo "  - Or edit directly and run 'devbox global shellenv' to reload"
echo ""
echo "Useful commands:"
echo "  devbox global list         # Show installed global packages"
echo "  devbox global add <pkg>    # Add a package globally"
echo "  devbox global rm <pkg>     # Remove a package globally"
echo "  devbox search <pkg>        # Search for packages"

echo ""
echo "=============================================================================="
echo "Setting up direnv (environment switcher)..."
echo "=============================================================================="

# Check if direnv is available (now managed by devbox)
if command -v direnv &> /dev/null; then
    echo "✓ direnv is installed"
    
    # Allow the .envrc file
    echo ""
    echo "Allowing ~/.envrc configuration..."
    direnv allow ~/.envrc
    echo "✓ ~/.envrc has been approved"
    
    echo ""
    echo "Configuration file: .envrc"
    echo "  - Edit ~/.envrc to set environment variables per directory"
    echo "  - Run 'direnv allow' after editing .envrc files"
    echo ""
    echo "Useful commands:"
    echo "  direnv allow           # Approve current directory's .envrc"
    echo "  direnv deny            # Block current directory's .envrc"
    echo "  direnv reload          # Reload current directory's .envrc"
else
    echo "⚠ direnv not found. It should be installed via devbox global packages."
fi

echo ""
echo "=============================================================================="
echo "Done! Review and edit PACKAGES array in ${BASH_SOURCE[0]} to customize."
echo "Remove any packages you don't need before running this script on a new machine."
echo ""
echo "Next steps:"
echo "  1. Reload your shell: exec \$SHELL -l"
echo "  2. Verify devbox: devbox global list"
echo "  3. Check installed tools: node --version, python --version, etc."
echo "=============================================================================="
