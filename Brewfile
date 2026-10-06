# Brewfile for CLI tools and GUI applications
# GNU tools install g-prefixed (gsed, gdate, ...); never add libexec/gnubin to PATH.
# Language runtimes (node, java, go, ...) are managed by mise, not here.
#
# Usage:
#   brew bundle install          # Install all packages
#   brew bundle cleanup --force  # Remove packages not in this file
#   brew bundle check            # Check if all packages are installed

# ============================================================================
# Formulae (CLI Tools)
# ============================================================================

# App Store CLI: install Mac App Store apps from terminal
# Note: mas is macOS-specific and requires deep system integration with the Mac App Store
brew "mas"

# === Core CLI ===
brew "coreutils"
brew "findutils"
brew "gnu-sed"
brew "grep"
brew "make"
brew "moreutils"
brew "bash"
brew "zsh"
brew "zsh-autosuggestions"
brew "zsh-completions"
brew "zsh-syntax-highlighting"
brew "curl"
brew "wget"
brew "git"
brew "git-lfs"
brew "git-delta"
brew "difftastic"
brew "gh"
brew "glab"
brew "gnupg"
brew "pinentry-mac"
brew "openssh"
brew "mise"
brew "fzf"
brew "zoxide"
brew "mcfly"
brew "atuin"
brew "bat"
brew "eza"
brew "fd"
brew "lsd"
brew "ripgrep"
brew "sd"
brew "xh"
brew "jq"
brew "just"
brew "hyperfine"
brew "tokei"
brew "watchexec"
brew "ouch"
brew "tree"
brew "tldr"
brew "htop"
brew "watch"
brew "midnight-commander"
brew "rename"

# === Archives and compression ===
brew "unzip"
brew "p7zip"
brew "xz"
brew "zstd"
brew "lz4"
brew "brotli"
brew "pigz"
brew "zopfli"
brew "libarchive"
brew "cabextract"

# === Libraries and build tools ===
brew "sqlite"
brew "openssl@3"
brew "pkgconf"
brew "cmake"
brew "maven"
brew "libpq"
brew "rustup"
brew "python@3.12"

# === Media ===
brew "ffmpeg"
brew "imagemagick"
brew "ghostscript"
brew "yt-dlp"

# === Cloud, containers and Kubernetes ===
brew "act"
brew "argocd"
brew "awscli"
brew "azure-cli"
brew "colima"
brew "doctl"
brew "hcloud"
brew "heroku"
brew "helm"
brew "helm@3"
brew "helmfile"
brew "k9s"
brew "kubernetes-cli"
brew "lazydocker"
brew "lazygit"
brew "minikube"
brew "terragrunt"
brew "speedtest-cli"
brew "nmap"
brew "geckodriver"
brew "bun"

# === Taps ===
tap "hashicorp/tap"
brew "hashicorp/tap/terraform"
tap "anomalyco/tap"
brew "anomalyco/tap/opencode"

# ============================================================================
# Casks (GUI Applications)
# ============================================================================

# === Browsers ===
# Firefox: privacy-focused browser, great dev tools
cask "firefox"
# Zen: minimalist browser
cask "zen@twilight"
# Chrome: good for testing
cask "google-chrome"

# === Development tools ===
# JetBrains Toolbox: manage JetBrains IDEs
cask "jetbrains-toolbox"
# VS Code: powerful code editor with extensions
cask "visual-studio-code"
# Modern terminal: AI-powered terminal with modern UI
cask "warp"
# Fast Docker: faster Docker alternative for Mac, replaces Docker Desktop
cask "orbstack"
# API test: test REST APIs with GUI
cask "postman"
# k8s IDE: visual Kubernetes management
cask "lens"
# Browser driver: Selenium/WebDriver Chrome driver
cask "chromedriver"
# Tunnels: expose local ports
cask "ngrok"
# PowerShell: cross-platform shell
cask "powershell"
# 1Password CLI
cask "1password-cli"

# === Productivity and utilities ===
# Passwords: secure password manager
cask "1password"
# Launcher: Spotlight replacement with plugins
cask "raycast"
# Share input: share keyboard/mouse across computers
cask "barrier"
# Clipboard manager: modern, lightweight clipboard history
cask "maccy"

# === Media and entertainment ===
# Audio player: advanced audio player
cask "foobar2000"
# Audio edit: record/edit audio
cask "audacity"
# Music tag: auto-tag music files
cask "musicbrainz-picard"
# Gaming: PC game platform
cask "steam"
# Epic Games: play Epic/GOG games
cask "heroic"

# === Communication ===
# Team chat: workplace communication
cask "slack"

# === System tools and utilities ===
# Mac maintenance: clean/optimize macOS
cask "onyx"
# Uninstaller: completely remove apps
cask "appcleaner"
# Archives: extract AND create archives with GUI, handles formats macOS can't (RAR, 7z, etc.)
cask "keka"
# Gestures: advanced trackpad/mouse gesture control
cask "jitouch"

# === Remote access ===
# Remote desktop: remote computer access
cask "teamviewer"

# === Backup and sync ===
# rsync GUI: visual rsync file sync
cask "rsyncui"
# Torrent: lightweight BitTorrent client
cask "transmission"