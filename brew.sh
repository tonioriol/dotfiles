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

echo "Updating Homebrew and upgrading existing packages..."
brew update
brew upgrade

BREW_PREFIX="$(brew --prefix)"

# All packages (formulae and casks merged - Homebrew 4.0+ handles both)
PACKAGES=(
# === Core utilities and system tools ===
coreutils          # GNU ls/cat/etc: cross-platform scripts need consistent behavior vs BSD variants (upstream+yours)
moreutils          # sponge/ifdata: useful for piping output back to same file safely (upstream)
findutils          # GNU find/xargs: more features than macOS BSD find, better for complex searches (upstream)
gnu-sed            # GNU sed: scripts using -i, -r flags need GNU syntax vs macOS BSD sed (upstream)

# === Shell and completion ===
zsh                # Latest zsh: newer features than system zsh (macOS default shell since Catalina)
zsh-completions    # Extra completions: better tab-complete for docker/git/kubectl
zsh-autosuggestions # Fish-like autosuggestions for zsh
zsh-syntax-highlighting # Fish-like syntax highlighting for zsh

# === Version control ===
git                # Latest git: newer features/security vs system git (upstream)
git-lfs            # Large files: track binaries/media in git without bloating repo (upstream+yours)
gh                 # GitHub CLI: create PRs, manage issues without browser (yours)
glab               # GitLab CLI: same as gh but for GitLab projects (yours)

# === Network tools ===
curl               # Latest curl: newer protocols/security vs system curl (yours)
wget               # Robust downloads: better for scripts, resume support vs curl (upstream+yours)
openssh            # Latest SSH: newer ciphers/security vs system openssh (upstream)

# === Security and encryption ===
gnupg              # GPG signing: sign commits/emails, encrypt files (upstream+yours)
pinentry-mac       # macOS GPG UI: native macOS keychain integration, includes pinentry functionality (yours)
openssl@3          # Modern SSL: latest security, most software uses this (yours)

mise               # Modern version manager: faster Rust-based alternative to asdf
                   # Manages Node, Python, Ruby, Go, Rust, Java, etc. with better performance
                   # Drop-in replacement for asdf with improved UX and speed
                   # See: https://mise.jdx.dev/

direnv             # Environment switcher: automatically load/unload environment variables per directory
                   # Works with .envrc files, integrates with mise and other tools
                   # See: https://direnv.net/

devbox             # Reproducible dev environments powered by Nix (like package.json for your entire environment)
                   # Creates isolated, reproducible development environments per project
                   # See: https://www.jetpack.io/devbox

# === Cloud and infrastructure tools ===
# awscli managed by mise - see .mise.toml (uncomment if needed)
azure-cli          # Azure: manage Azure resources from terminal (yours)
doctl              # DigitalOcean: manage droplets/k8s from terminal (yours)
heroku             # Heroku: deploy/manage Heroku apps (yours)

# === Kubernetes and container orchestration ===
# kubectl managed by mise - see .mise.toml (uncomment if needed)
# helm managed by mise - see .mise.toml (uncomment if needed)
helmfile           # Helm automation: declarative multi-chart deployments (yours)
k9s                # k8s TUI: visual cluster management in terminal (yours)
minikube           # Local k8s: test k8s locally before cloud deploy (yours)

# === Infrastructure as Code ===
# terraform managed by mise - see .mise.toml
terragrunt         # Terraform DRY: reduce Terraform code duplication (yours)

# === Development tools and build systems ===
gcc                # GNU compiler: compile C/C++, newer than Xcode's (upstream+yours)
make               # Build tool: run Makefiles, essential for many projects (upstream+yours)
cmake              # Cross-platform build: modern C/C++ build system (implied)
# maven managed by mise - see .mise.toml (uncomment if needed)
pkgconf            # pkg-config: find library compile/link flags (yours)

# === Database clients and servers ===
sqlite             # SQLite: embedded DB, great for local dev/testing (yours)

# === Text processing and utilities ===
jq                 # JSON: parse/transform JSON in shell scripts (upstream+yours)
grep               # GNU grep: better regex than macOS BSD grep (upstream)
ripgrep            # Fast search: faster than grep/ack, respects .gitignore (yours)
fd                 # Fast find: faster than find, simpler syntax (yours)
fzf                # Fuzzy finder: interactive file/history search (yours)
tree               # Dir tree: visualize directory structure (upstream+yours)
bat                # Better cat: syntax highlighting and git integration (recommended)
eza                # Modern ls: better than lsd, successor to exa (recommended)
lsd                # Modern ls: colorful ls with icons (yours)
tldr               # Quick help: simplified man pages with examples (yours)
delta              # Better git diff: syntax highlighting and side-by-side diffs (recommended)
zoxide             # Smarter cd: learns your habits, jump to frequent directories (recommended)
pcregrep           # PCRE grep: Perl-compatible regex grep (implied)

# === Terminal tools ===
htop               # Process viewer: better than top, interactive (yours)
mc                 # File manager: TUI file manager like Norton Commander (yours)
mcfly              # Smart history: AI-powered shell history search (yours)
lazygit            # Terminal UI for git: visual git operations (recommended)
lazydocker         # Terminal UI for docker: visual docker management (recommended)

# === Multimedia and imaging ===
ffmpeg             # Video/audio: convert/edit video/audio files (yours)
imagemagick        # Image edit: convert/resize/edit images from CLI (upstream+yours)
ghostscript        # PDF/PS: render PostScript/PDF files (yours)

# === Compression and archiving ===
p7zip              # 7z archives: extract .7z files (upstream+yours)
xz                 # XZ compress: better compression than gzip (upstream+yours)
zstd               # Fast compress: faster than gzip, better ratio (yours)
lz4                # Ultra-fast: fastest compression, lower ratio (yours)
brotli             # Web compress: used by web servers for compression (yours)
zopfli             # Best gzip: slowest but best gzip compression (upstream)
pigz               # Parallel gzip: multi-core gzip compression (upstream)
libarchive         # Archive lib: read/write many archive formats (yours)
unzip              # Unzip: extract .zip files (yours)
cabextract         # CAB files: extract Windows .cab files (yours)

# === Networking and protocols ===
nmap               # Port scanner: scan networks/ports for security (upstream)
speedtest-cli      # Speed test: test internet speed from CLI (yours)
# deno managed by mise - see .mise.toml (uncomment if needed)
yt-dlp             # Video download: maintained fork of youtube-dl, faster and more features (yours)

mas                # App Store CLI: install Mac App Store apps from terminal (yours)
rename             # Batch rename: Perl-based file renamer for bulk operations (upstream)
watch              # Monitor: run command periodically, watch output changes (upstream)

llvm               # Compiler: LLVM compiler infrastructure (yours)
act                # GitHub Actions: test GitHub Actions locally (yours)
geckodriver        # Firefox driver: WebDriver for Firefox automation (yours)

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
chromedriver       # Chrome driver: automate Chrome browser (yours)
lens               # k8s IDE: visual Kubernetes management (yours)

# === Productivity and utilities ===
1password          # Passwords: secure password manager (upstream+yours)
1password-cli      # 1Password CLI: access passwords from terminal (yours)
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
ngrok              # Tunnels: expose localhost to internet securely (yours)

# === Fonts ===
font-monaspace     # Monaspace: modern monospace font family for coding (yours)

# === Remote access ===
teamviewer         # Remote desktop: remote computer access (upstream)

# === Design and content ===
canva              # Design: graphic design tool (yours)

# === Backup and sync ===
rsyncui            # rsync GUI: visual rsync file sync (yours)
transmission       # Torrent: lightweight BitTorrent client (upstream)

# === Shell and command line ===
powershell         # PowerShell: Microsoft's cross-platform shell (yours)
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

# Install all packages in one command - brew handles parallelization and skips already installed
if [ ${#TO_INSTALL[@]} -gt 0 ]; then
  echo "Installing ${#TO_INSTALL[@]} packages (brew will parallelize and skip already installed)..."
  brew install "${TO_INSTALL[@]}" || echo "Some packages failed to install"
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
echo "Setting up mise (version manager)..."
echo "=============================================================================="

# Check if mise was installed
if command -v mise &> /dev/null; then
    echo "✓ mise is installed"
    
    # Trust the .mise.toml configuration file
    echo ""
    echo "Trusting ~/.mise.toml configuration..."
    mise trust ~/.mise.toml
    
    # Install tools from .mise.toml
    echo ""
    echo "Installing tools from .mise.toml..."
    mise install || echo "⚠ Failed to install some tools from .mise.toml"
    
    echo ""
    echo "✓ Tools installed via mise (from .mise.toml):"
    mise list 2>/dev/null || echo "  No tools installed yet"
    echo ""
    echo "Configuration file: .mise.toml"
    echo "  - Edit .mise.toml to add/remove tools"
    echo "  - Uncomment tools like terraform, kubectl, ruby, go, etc."
    echo "  - Run 'mise install' to apply changes"
    echo ""
    echo "Useful commands:"
    echo "  mise list              # Show installed tools"
    echo "  mise registry          # Show all available tools"
    echo "  mise use --global <tool>@<version>  # Install a tool globally"
    echo "  mise doctor            # Check mise configuration"
else
    echo "⚠ mise not found. Install it with: brew install mise"
fi

echo ""
echo "=============================================================================="
echo "Done! Review and edit PACKAGES array in ${BASH_SOURCE[0]} to customize."
echo "Remove any packages you don't need before running this script on a new machine."
echo ""
echo "Next steps:"
echo "  1. Reload your shell: exec \$SHELL -l"
echo "  2. Verify mise: mise doctor"
echo "  3. Check installed tools: mise list"
echo "=============================================================================="
