#!/usr/bin/env bash
# Comprehensive brew.sh — includes all formulae/casks from upstream dotfiles + your machine.
# Each entry is documented with its purpose and source (upstream/your-machine).
# Edit this file to remove packages you don't want before running.
set -euo pipefail

echo "Updating Homebrew and upgrading existing packages..."
brew update
brew upgrade --cleanup

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

asdf               # Universal version manager: manage ALL language versions (Node, Python, Ruby, Go, Rust, Java, etc.)
                   # After install: asdf plugin add nodejs python ruby golang rust java
                   # Then: asdf install nodejs latest && asdf global nodejs latest
                   # See: https://asdf-vm.com/

# === Cloud and infrastructure tools ===
awscli             # AWS: manage S3/EC2/Lambda from terminal (yours)
azure-cli          # Azure: manage Azure resources from terminal (yours)
doctl              # DigitalOcean: manage droplets/k8s from terminal (yours)
heroku             # Heroku: deploy/manage Heroku apps (yours)

# === Kubernetes and container orchestration ===
kubernetes-cli     # kubectl: manage k8s clusters, deploy apps (yours)
helm               # k8s packages: install/manage k8s apps via charts (yours)
helmfile           # Helm automation: declarative multi-chart deployments (yours)
k9s                # k8s TUI: visual cluster management in terminal (yours)
minikube           # Local k8s: test k8s locally before cloud deploy (yours)

# === Infrastructure as Code ===
terraform          # IaC: provision cloud infrastructure as code (yours)
terragrunt         # Terraform DRY: reduce Terraform code duplication (yours)

# === Development tools and build systems ===
gcc                # GNU compiler: compile C/C++, newer than Xcode's (upstream+yours)
make               # Build tool: run Makefiles, essential for many projects (upstream+yours)
cmake              # Cross-platform build: modern C/C++ build system (implied)
maven              # Java build: build/manage Java projects (yours)
pkgconf            # pkg-config: find library compile/link flags (yours)

# === Database clients and servers ===
sqlite             # SQLite: embedded DB, great for local dev/testing (yours)

# === Text processing and utilities ===
jq                 # JSON: parse/transform JSON in shell scripts (upstream+yours)
grep               # GNU grep: better regex than macOS BSD grep (upstream)
ack                # Code search: search code ignoring .git/node_modules, kept for compatibility (upstream)
ripgrep            # Fast search: faster than grep/ack, respects .gitignore (yours)
fd                 # Fast find: faster than find, simpler syntax (yours)
fzf                # Fuzzy finder: interactive file/history search (yours)
tree               # Dir tree: visualize directory structure (upstream+yours)
lsd                # Modern ls: colorful ls with icons (yours)
tldr               # Quick help: simplified man pages with examples (yours)
pcregrep           # PCRE grep: Perl-compatible regex grep (implied)

# === Multiplexers and terminal tools ===
tmux               # Terminal multiplexer: multiple terminals in one window (yours)
htop               # Process viewer: better than top, interactive (yours)
mc                 # File manager: TUI file manager like Norton Commander (yours)
mcfly              # Smart history: AI-powered shell history search (yours)

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
wireshark          # Packet capture: analyze network traffic (yours)
nmap               # Port scanner: scan networks/ports for security (upstream)
speedtest-cli      # Speed test: test internet speed from CLI (yours)
deno               # Modern JS: secure TypeScript/JS runtime, alternative to Node (yours)
yt-dlp             # Video download: maintained fork of youtube-dl, faster and more features (yours)

mas                # App Store CLI: install Mac App Store apps from terminal (yours)
rename             # Batch rename: Perl-based file renamer for bulk operations (upstream)
watch              # Monitor: run command periodically, watch output changes (upstream)

gdb                # Debugger: GNU debugger for C/C++ (implied)
llvm               # Compiler: LLVM compiler infrastructure (yours)
act                # GitHub Actions: test GitHub Actions locally (yours)
geckodriver        # Firefox driver: WebDriver for Firefox automation (yours)

# === GUI Applications ===

# === Browsers ===
google-chrome      # Chrome: fast browser, good dev tools (upstream+yours)
firefox            # Firefox: privacy-focused browser, great dev tools (upstream+yours)
microsoft-edge     # Edge: Chromium-based, good for testing (yours)
zen-browser        # Zen: minimalist browser (yours)

# === Development tools ===
visual-studio-code # VS Code: powerful code editor with extensions (upstream+yours)
warp               # Modern terminal: AI-powered terminal with modern UI (yours)
orbstack           # Fast Docker: faster Docker alternative for Mac, replaces Docker Desktop (yours)
postman            # API test: test REST APIs with GUI (upstream+yours)
chromedriver       # Chrome driver: automate Chrome browser (yours)
lens               # k8s IDE: visual Kubernetes management (yours)

# === Productivity and utilities ===
1password          # Passwords: secure password manager (upstream+yours)
1password-cli      # 1Password CLI: access passwords from terminal (yours)
raycast            # Launcher: Spotlight replacement with plugins (upstream+yours)
rectangle          # Window mgmt: snap windows with keyboard shortcuts (upstream)
barrier            # Share input: share keyboard/mouse across computers (yours)
flycut             # Clipboard: clipboard history manager (upstream legacy)

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
for pkg in "${PACKAGES[@]}"; do
  # Skip comments and empty lines
  [[ "$pkg" =~ ^#.*$ ]] && continue
  [[ -z "$pkg" ]] && continue
  
  # Extract package name (everything before first space/comment)
  pkg_name=$(echo "$pkg" | awk '{print $1}')
  
  # Check if already installed (works for both formulae and casks)
  if brew list "$pkg_name" &>/dev/null; then
    echo " - ${pkg_name} already installed"
  else
    echo " - installing ${pkg_name}"
    brew install "${pkg_name}" || echo "Failed to install ${pkg_name}"
  fi
done

# Add brew-installed bash to /etc/shells if present (do not change user shell automatically)
if [ -x "${BREW_PREFIX}/bin/bash" ] && ! grep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "Adding ${BREW_PREFIX}/bin/bash to /etc/shells (requires sudo)"
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells
fi

echo "Running brew cleanup..."
brew cleanup

echo "Done. Review and edit PACKAGES array in ${BASH_SOURCE[0]} to customize."
echo "Remove any packages you don't need before running this script on a new machine."
