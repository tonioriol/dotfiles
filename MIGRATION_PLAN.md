# Migration Plan: mise + Homebrew → devbox + Homebrew

**Document Version:** 2.0
**Date:** 2025-11-15
**Status:** Ready for Review - GUI Strategy Finalized

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State Analysis](#2-current-state-analysis)
3. [Target Architecture](#3-target-architecture)
4. [GUI Application Strategy](#4-gui-application-strategy)
5. [Devbox Global Configuration](#5-devbox-global-configuration)
6. [Homebrew Streamlining](#6-homebrew-streamlining)
7. [File Modifications](#7-file-modifications)
8. [Migration Steps](#8-migration-steps)
9. [Testing Strategy](#9-testing-strategy)
10. [Rollback Plan](#10-rollback-plan)
11. [Post-Migration](#11-post-migration)

---

## 1. Executive Summary

### Migration Goal
Transition from **mise + Homebrew** to **devbox + Homebrew** hybrid architecture where:
- **devbox** manages all CLI development tools (replacing mise entirely)
- **Homebrew** only handles GUI applications and macOS-specific tools

### Key Benefits
- **Better Reproducibility:** Nix-based package management ensures consistent environments
- **Improved Isolation:** No conflicts between system and development tools
- **Larger Ecosystem:** Access to 80,000+ Nix packages vs ~500 mise tools
- **Cleaner Architecture:** Clear separation between CLI and GUI tools
- **Easier Onboarding:** New team members get identical environments

### Migration Timeline
- **Preparation:** 10 minutes (backups, verification)
- **Execution:** 20-25 minutes (file changes, package installation)
- **Testing:** 10-15 minutes (smoke tests, validation)
- **Total:** ~45 minutes

### Risk Level
**Low** - Comprehensive rollback plan available, non-destructive changes

---

## 2. Current State Analysis

### 2.1 mise Configuration (`.mise.toml`)

Currently managing **8 development tools**:

| Tool | Version | Purpose |
|------|---------|---------|
| node | lts | JavaScript runtime |
| python | 3.12 | Python interpreter |
| deno | latest | Modern JS/TS runtime |
| terraform | latest | Infrastructure as Code |
| kubectl | latest | Kubernetes CLI |
| helm | latest | Kubernetes package manager |
| awscli | latest | AWS CLI |
| maven | latest | Java build tool |

### 2.2 Homebrew Configuration (`brew.sh`)

Currently installing **~150 packages** including:
- **~110 CLI tools** (moving to devbox, except `mas` which is macOS-specific)
- **~40 GUI applications** (staying in Homebrew)

### 2.3 Bootstrap Process (`bootstrap.sh`)

Current flow:
1. rsync dotfiles to home directory
2. Run `brew.sh` (installs all packages)
3. Run `.macos` (configure macOS settings)

### 2.4 Shell Integration (`.zshrc`)

- Lines 58-64: mise activation with `eval "$(mise activate zsh)"`
- Lines 66-71: direnv integration (compatible with devbox)

---

## 3. Target Architecture

### 3.1 Hybrid Approach

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Environment                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │   devbox (Nix)       │      │   Homebrew (macOS)   │   │
│  ├──────────────────────┤      ├──────────────────────┤   │
│  │ • CLI Tools (~80)    │      │ • GUI Apps (~40)     │   │
│  │ • Programming langs  │      │ • macOS-specific     │   │
│  │ • Cloud tools        │      │ • Browsers           │   │
│  │ • Build systems      │      │ • Development IDEs   │   │
│  │ • Text processing    │      │ • Productivity apps  │   │
│  │ • Compression utils  │      │ • Media players      │   │
│  └──────────────────────┘      └──────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Decision Matrix

| Package Type | Tool | Reason |
|--------------|------|--------|
| CLI development tool | devbox | Better isolation, reproducibility |
| GUI application | Homebrew | Native macOS integration required |
| macOS system tool | Homebrew | System-level integration needed |
| Font | Homebrew | System font installation |

---

## 4. GUI Application Strategy

### 4.1 Research Findings: Nix GUI Apps on macOS

After thorough research, here are the key findings about GUI application support in Nix/devbox on macOS:

#### Known Issues with Nix GUI Apps on macOS

1. **Spotlight Integration Problem**
   - Nix apps are symlinked to `~/Applications/Nix Apps/`
   - macOS Spotlight doesn't index symlinks by default
   - Apps won't appear in Spotlight search or Launchpad

2. **Dock Persistence Issue**
   - Apps pinned to Dock become "missing question marks" after Nix rebuild
   - Requires re-pinning apps after every system update
   - Frustrating user experience for frequently used apps

3. **File Association Challenges**
   - Setting Nix apps as default for file types can be problematic
   - macOS may not recognize symlinked apps for "Open With" menus

#### Available Solution: mac-app-util

**Tool:** [`mac-app-util`](https://github.com/hraban/mac-app-util)

**What it does:**
- Creates "trampoline apps" that macOS recognizes as real applications
- Enables Spotlight indexing of Nix-installed GUI apps
- Maintains Dock persistence across rebuilds
- Requires nix-darwin or home-manager integration

**Limitations:**
- Requires additional setup and configuration
- Adds complexity to the dotfiles setup
- Not officially supported by devbox (requires nix-darwin/home-manager)
- May still have edge cases with certain apps

### 4.2 Recommendation: Keep GUI Apps in Homebrew

**Decision:** Continue using Homebrew for GUI applications

**Rationale:**

| Factor | Homebrew | Nix + mac-app-util | Winner |
|--------|----------|-------------------|--------|
| Spotlight integration | ✅ Native | ⚠️ Requires setup | Homebrew |
| Dock persistence | ✅ Works perfectly | ⚠️ Needs trampolines | Homebrew |
| File associations | ✅ Native | ⚠️ May have issues | Homebrew |
| Setup complexity | ✅ Simple | ❌ Complex | Homebrew |
| Maintenance | ✅ Low | ⚠️ Medium | Homebrew |
| macOS integration | ✅ Excellent | ⚠️ Good with workarounds | Homebrew |
| Reproducibility | ⚠️ Good | ✅ Excellent | Nix |

**Key Points:**

1. **Pragmatism over Purity:** While Nix offers better reproducibility, GUI apps benefit more from native macOS integration than from Nix's reproducibility guarantees

2. **User Experience:** Spotlight search and Dock persistence are critical for daily workflow. The workarounds add friction that outweighs the benefits

3. **Maintenance Burden:** Adding nix-darwin or home-manager just for GUI app integration significantly increases complexity

4. **Hybrid Approach Works:** CLI tools benefit greatly from Nix's reproducibility and isolation, while GUI apps work better with Homebrew's native integration

5. **Community Consensus:** Many experienced Nix users on macOS keep GUI apps in Homebrew for these exact reasons

### 4.3 Final Architecture Decision

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Environment                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │   devbox (Nix)       │      │   Homebrew (macOS)   │   │
│  ├──────────────────────┤      ├──────────────────────┤   │
│  │ • CLI Tools (~97)    │      │ • GUI Apps (~40)     │   │
│  │ • Programming langs  │      │ • macOS-specific     │   │
│  │ • Cloud tools        │      │ • Browsers           │   │
│  │ • Build systems      │      │ • Development IDEs   │   │
│  │ • Text processing    │      │ • Productivity apps  │   │
│  │ • Compression utils  │      │ • Media players      │   │
│  │ • Version control    │      │ • System utilities   │   │
│  └──────────────────────┘      └──────────────────────┘   │
│                                                              │
│  Benefits:                      Benefits:                   │
│  • Reproducible                 • Native Spotlight          │
│  • Isolated                     • Dock persistence          │
│  • Version pinning              • File associations         │
│  • 80k+ packages                • Zero setup friction       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**This hybrid approach provides:**
- ✅ Best-in-class CLI tool management via devbox/Nix
- ✅ Seamless macOS GUI app experience via Homebrew
- ✅ Clear separation of concerns
- ✅ Minimal complexity and maintenance
- ✅ Excellent user experience for both CLI and GUI workflows

### 4.4 Future Considerations

If you want to explore Nix GUI apps in the future:

1. **Prerequisites:**
   - Install nix-darwin or home-manager
   - Configure mac-app-util
   - Test thoroughly with your most-used apps

2. **Migration Path:**
   - Start with 1-2 non-critical GUI apps
   - Validate Spotlight, Dock, and file associations
   - Gradually migrate more apps if satisfied

3. **Resources:**
   - [mac-app-util GitHub](https://github.com/hraban/mac-app-util)
   - [nix-darwin](https://github.com/LnL7/nix-darwin)
   - [home-manager](https://github.com/nix-community/home-manager)

---

## 5. Devbox Global Configuration

### 4.1 Complete `devbox.json` Structure

Create `.devbox-global.json` in the repository root:

```json
{
  "$schema": "https://raw.githubusercontent.com/jetify-com/devbox/main/devbox.schema.json",
  "packages": [
    "nodejs@latest",
    "python312",
    "deno@latest",
    "terraform@latest",
    "kubectl@latest",
    "kubernetes-helm@latest",
    "awscli2@latest",
    "maven@latest",
    "coreutils@latest",
    "moreutils@latest",
    "findutils@latest",
    "gnused@latest",
    "zsh@latest",
    "git@latest",
    "git-lfs@latest",
    "gh@latest",
    "glab@latest",
    "curl@latest",
    "wget@latest",
    "openssh@latest",
    "gnupg@latest",
    "pinentry_mac@latest",
    "openssl_3@latest",
    "azure-cli@latest",
    "doctl@latest",
    "heroku@latest",
    "helmfile@latest",
    "k9s@latest",
    "minikube@latest",
    "terragrunt@latest",
    "gcc@latest",
    "gnumake@latest",
    "cmake@latest",
    "pkg-config@latest",
    "sqlite@latest",
    "jq@latest",
    "gnugrep@latest",
    "ripgrep@latest",
    "fd@latest",
    "fzf@latest",
    "tree@latest",
    "bat@latest",
    "eza@latest",
    "lsd@latest",
    "tldr@latest",
    "delta@latest",
    "zoxide@latest",
    "pcre@latest",
    "htop@latest",
    "mc@latest",
    "mcfly@latest",
    "lazygit@latest",
    "lazydocker@latest",
    "ffmpeg@latest",
    "imagemagick@latest",
    "ghostscript@latest",
    "p7zip@latest",
    "xz@latest",
    "zstd@latest",
    "lz4@latest",
    "brotli@latest",
    "zopfli@latest",
    "pigz@latest",
    "libarchive@latest",
    "unzip@latest",
    "cabextract@latest",
    "nmap@latest",
    "speedtest-cli@latest",
    "yt-dlp@latest",
    "rename@latest",
    "watch@latest",
    "llvm@latest",
    "act@latest",
    "geckodriver@latest",
    "chromedriver@latest",
    "direnv@latest",
    "zsh-completions@latest",
    "zsh-autosuggestions@latest",
    "zsh-syntax-highlighting@latest",
    "_1password@latest",
    "powershell@latest",
    "ngrok@latest",
    "nmap@latest",
    "speedtest-cli@latest",
    "yt-dlp@latest",
    "rename@latest",
    "watch@latest",
    "llvm@latest",
    "act@latest",
    "geckodriver@latest"
  ],
  "shell": {
    "init_hook": [
      "echo 'Devbox global environment loaded'",
      "echo 'Run devbox global list to see installed packages'"
    ]
  }
}
```

### 4.2 Package Count Summary

- **Total packages in devbox:** ~97
- **From mise:** 8 tools
- **From brew.sh CLI tools:** ~89 tools (all CLI tools except `mas`)
- **Remaining in Homebrew:** 1 CLI tool (`mas`) + ~40 GUI applications

### 4.3 Version Strategy

| Strategy | When to Use | Examples |
|----------|-------------|----------|
| `@latest` | Stable tools, frequent updates desired | git, jq, terraform |
| `@lts` | Long-term support needed | nodejs (use `nodejs@lts`) |
| Specific version | Critical dependencies | python312, openssl_3 |

### 4.4 Package Name Mapping

| Homebrew/mise | Nix (devbox) | Notes |
|---------------|--------------|-------|
| `node` | `nodejs` | Use nodejs or nodejs-18_x |
| `python` | `python312` | Specify version |
| `gnu-sed` | `gnused` | GNU version |
| `openssl@3` | `openssl_3` | Underscore, not @ |
| `pinentry-mac` | `pinentry_mac` | Underscore |
| `awscli` | `awscli2` | Version 2 |
| `make` | `gnumake` | GNU make |
| `grep` | `gnugrep` | GNU grep |
| `1password-cli` | `_1password` | Underscore prefix, no -cli suffix |

---

## 5. Homebrew Streamlining

### 5.1 Packages to REMOVE from `brew.sh`

**Lines 21-139, plus scattered entries** - Remove these CLI tools (moving to devbox):

```bash
# Remove these lines (21-139, 157, 162, 189, 205):
coreutils
moreutils
findutils
gnu-sed
zsh
zsh-completions
zsh-autosuggestions
zsh-syntax-highlighting
git
git-lfs
gh
glab
curl
wget
openssh
gnupg
pinentry-mac
openssl@3
azure-cli
doctl
heroku
helmfile
k9s
minikube
terragrunt
gcc
make
cmake
pkgconf
sqlite
jq
grep
ripgrep
fd
fzf
tree
bat
eza
lsd
tldr
delta
zoxide
pcregrep
htop
mc
mcfly
lazygit
lazydocker
ffmpeg
imagemagick
ghostscript
p7zip
xz
zstd
lz4
brotli
zopfli
pigz
libarchive
unzip
cabextract
nmap
speedtest-cli
yt-dlp
rename
watch
llvm
act
geckodriver
chromedriver       # Line 157
1password-cli      # Line 162
ngrok              # Line 189
powershell         # Line 205
nmap               # Line 128
speedtest-cli      # Line 129
yt-dlp             # Line 131
rename             # Line 134
watch              # Line 135
llvm               # Line 137
act                # Line 138
geckodriver        # Line 139
```

**Lines 48-59** - Remove mise, devbox, and direnv (all moving to devbox):

```bash
# REMOVE:
mise               # Being replaced by devbox
devbox             # Will be installed via curl, not Homebrew
direnv             # Moving to devbox for consistency
```

**Lines 240-274** - Remove entire mise setup section

### 5.2 Packages to KEEP in `brew.sh`

**Line 133** - macOS-specific CLI tool:
```bash
mas                # Mac App Store CLI: install Mac App Store apps from terminal (yours)
```
**Reason:** `mas` is macOS-specific and requires deep system integration with the Mac App Store. It cannot be properly packaged in Nix/devbox.

**Lines 143-206** - GUI Applications (keep all):
```bash
# Browsers
google-chrome
firefox
microsoft-edge
zen@twilight

# Development tools
visual-studio-code
warp
orbstack
colima
postman
lens

# Productivity
1password
raycast
barrier
maccy

# Media
spotify
foobar2000
steam
openemu
audacity
musicbrainz-picard
heroic

# Communication
slack

# System tools
onyx
appcleaner
keka

# Networking
wireshark
fing
angry-ip-scanner
netspot

# Fonts
font-monaspace

# Remote access
teamviewer

# Design
canva

# Backup
rsyncui
transmission
```

### 5.3 New Devbox Installation and Setup Section

Add after line 274 (replacing mise setup section):

```bash
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

# Copy global configuration if it exists in dotfiles
if [ -f ~/.devbox-global.json ]; then
    echo "Installing devbox global packages from ~/.devbox-global.json..."
    devbox global pull ~/.devbox-global.json
    echo "✓ Devbox global packages installed"
else
    echo "⚠ ~/.devbox-global.json not found. Skipping global package installation."
fi

echo ""
echo "Configuration file: ~/.devbox-global.json"
echo "  - Edit to add/remove global packages"
echo "  - Run 'devbox global pull ~/.devbox-global.json' to apply changes"
echo ""
echo "Useful commands:"
echo "  devbox global list         # Show installed global packages"
echo "  devbox global add <pkg>    # Add a package globally"
echo "  devbox global rm <pkg>     # Remove a package globally"
echo "  devbox search <pkg>        # Search for packages"
```

---

## 6. File Modifications

### 6.1 `.devbox-global.json` (NEW FILE)

**Action:** Create new file in repository root

**Content:** See section 4.1 for complete JSON structure

**Purpose:** Version-controlled devbox global configuration

### 6.2 `brew.sh` Modifications

**File:** `brew.sh`

**Changes:**

1. **Lines 21-139, plus scattered entries:** Remove ~90 CLI tool entries (see section 5.1 for complete list)
2. **Lines 48-59:** Remove mise and devbox entries
3. **Lines 240-274:** Replace entire mise setup section with devbox installation and setup (see section 5.3)
4. **Lines 276-302:** Keep direnv setup section (unchanged)

### 6.3 `bootstrap.sh` Modifications

**File:** `bootstrap.sh`

**Changes:** Add devbox configuration copy before brew.sh

**Location:** After line 28 (after rsync, before brew.sh)

```bash
# Copy devbox global configuration
if [ -f .devbox-global.json ]; then
    echo ""
    echo "Copying devbox global configuration..."
    cp .devbox-global.json ~/.devbox-global.json
    echo "✓ Devbox configuration copied to ~/.devbox-global.json"
fi
```

### 6.4 `.zshrc` Modifications

**File:** `.zshrc`

**Changes:** Replace mise activation with devbox

**Lines 58-64:** Replace with:

```bash
# devbox - Reproducible development environments powered by Nix
# Manages CLI tools globally and per-project
# Install packages: devbox global add <package>
# See: https://www.jetify.com/devbox
if type devbox &>/dev/null; then
    eval "$(devbox global shellenv --init-hook)"
fi
```

### 6.5 `.mise.toml` (DELETE)

**Action:** Delete this file after migration is complete and validated

**Reason:** No longer needed, replaced by devbox

### 6.6 `README.md` Modifications

**File:** `README.md`

**Changes:**

**Lines 64-72:** Replace mise documentation with devbox:

```markdown
**Homebrew packages:** `./brew.sh` - Install GUI apps and macOS-specific tools
  - **devbox**: Development environment manager powered by Nix (see `.devbox-global.json`)
    - The bootstrap script automatically copies `.devbox-global.json` to your home directory
    - Global packages are installed automatically during setup
    - Use `devbox global add <package>` to add more tools
  - **direnv**: Environment switcher that loads `.envrc` files per directory
    - The bootstrap script automatically approves the `~/.envrc` configuration file
    - Edit `.envrc` to set environment variables that load automatically when you cd into directories

**Customize tools:** Edit `.devbox-global.json` to add/remove development tools. Search for packages at [search.nixos.org](https://search.nixos.org/packages).
```

**Lines 74-82:** Add new architecture section:

```markdown
## Hybrid Architecture: devbox + Homebrew

This setup uses a hybrid approach for package management:

- **devbox (Nix)**: Manages all CLI development tools (~97 packages)
  - Programming languages (Node.js, Python, Deno)
  - Cloud tools (AWS CLI, Azure CLI, kubectl, Terraform)
  - Build systems (gcc, make, cmake, maven)
  - Text processing (jq, ripgrep, fd, bat, eza)
  - Compression utilities (p7zip, xz, zstd)
  - Version control (git, gh, glab)
  
- **Homebrew**: Manages GUI applications and macOS-specific tools (~40 packages)
  - Browsers (Chrome, Firefox, Edge)
  - Development IDEs (VS Code, Warp)
  - Productivity apps (1Password, Raycast)
  - Media players (Spotify, Steam)
  - System utilities (OrbStack, Colima)

This separation provides:
- **Better reproducibility** for CLI tools via Nix
- **Native macOS integration** for GUI apps via Homebrew
- **Clear boundaries** between development and system tools
```

**Lines 92-156:** Update migration workflow:

```markdown
### On your new machine:
1. Clone this repository (git is pre-installed on macOS):
   ```shell
   git clone https://github.com/tonioriol/dotfiles.git && cd dotfiles
   ```

2. Copy your `.secrets/` directory from backup to the dotfiles directory

3. Create your `.extra` file from the template:
   ```shell
   cp .extra.template ~/.extra
   vim ~/.extra  # Edit with your personal information
   ```

4. Run the bootstrap script:
   ```shell
   ./bootstrap.sh
   ```
   This will:
   - Sync dotfiles to your home directory
   - Copy devbox global configuration
   - Install Homebrew packages (GUI apps + devbox)
   - Install devbox global packages (CLI tools)
   - Configure macOS settings

5. Verify devbox setup:
   ```shell
   devbox global list  # Should show ~97 packages
   node --version      # Should work from devbox
   python --version    # Should work from devbox
   ```

6. Restore your secrets:
   ```shell
   ./scripts/secrets.sh restore
   ```

7. If you use GPG signing, add your key ID to `~/.extra`:
   ```shell
   # Get your GPG key ID
   gpg --list-secret-keys --keyid-format=long
   
   # Edit ~/.extra and uncomment the GPG lines with your key ID
   vim ~/.extra
   
   # Reload configuration
   source ~/.extra
   ```

8. Restart your computer for all macOS settings to take effect
```

---

## 7. Migration Steps

### Phase 1: Preparation (5 minutes)

1. **Backup current configuration:**
   ```bash
   cp ~/.mise.toml ~/.mise.toml.backup
   cp ~/.zshrc ~/.zshrc.backup
   brew bundle dump --file=~/Brewfile.backup --force
   ```

2. **Document current tool versions:**
   ```bash
   mise list > ~/mise-versions-backup.txt
   ```

3. **Verify devbox is NOT installed yet:**
   ```bash
   # Devbox will be installed via curl during migration, not Homebrew
   command -v devbox && echo "devbox already installed" || echo "devbox not installed (expected)"
   ```

### Phase 2: Create Devbox Configuration (5 minutes)

4. **Create `.devbox-global.json`:**
   - Use content from section 4.1
   - Save in repository root

5. **Verify JSON syntax:**
   ```bash
   cat .devbox-global.json | jq . > /dev/null && echo "✓ Valid JSON"
   ```

### Phase 3: Update Configuration Files (5 minutes)

6. **Update `brew.sh`:**
   - Remove all CLI tools (lines 21-139, plus 128-129, 131, 134-135, 137-139, 157, 162, 189, 205)
   - Remove mise and devbox entries (lines 48-59)
   - Replace mise setup section with devbox installation and setup (lines 240-274, see section 5.3)
   - Remove direnv setup section (lines 276-302)

7. **Update `bootstrap.sh`:**
   - Add devbox configuration copy (see 6.3)

8. **Update `.zshrc`:**
   - Replace mise activation with devbox (see 6.4)

9. **Update `README.md`:**
   - Replace mise documentation with devbox (see 6.6)

### Phase 4: Install Devbox and Packages (10 minutes)

10. **Install devbox:**
    ```bash
    curl -fsSL https://get.jetify.com/devbox | bash
    export PATH="$HOME/.local/bin:$PATH"
    ```

11. **Copy devbox configuration:**
    ```bash
    cp .devbox-global.json ~/.devbox-global.json
    ```

12. **Initialize devbox global:**
    ```bash
    devbox global pull ~/.devbox-global.json
    ```

13. **Verify installation:**
    ```bash
    devbox global list
    ```

### Phase 5: Clean Up (5 minutes)

14. **Remove mise:**
    ```bash
    brew uninstall mise
    ```

15. **Remove Homebrew CLI tools:**
    ```bash
    # Remove tools now managed by devbox
    brew uninstall --ignore-dependencies \
      coreutils moreutils findutils gnu-sed zsh zsh-completions \
      zsh-autosuggestions zsh-syntax-highlighting git git-lfs gh glab \
      curl wget openssh gnupg pinentry-mac openssl@3 azure-cli doctl \
      heroku helmfile k9s minikube terragrunt gcc make cmake pkgconf \
      sqlite jq grep ripgrep fd fzf tree bat eza lsd tldr delta \
      zoxide htop mc mcfly lazygit lazydocker ffmpeg imagemagick \
      ghostscript p7zip xz zstd lz4 brotli zopfli pigz libarchive \
      unzip cabextract nmap speedtest-cli yt-dlp mas rename watch \
      llvm act geckodriver chromedriver 1password-cli ngrok powershell \
      nmap speedtest-cli yt-dlp rename watch direnv
    
    # Note: 'mas' stays in Homebrew (macOS-specific, requires App Store integration)
    ```

16. **Reload shell:**
    ```bash
    exec $SHELL -l
    ```

### Phase 6: Validation (5 minutes)

17. **Run smoke tests** (see section 8.1)

18. **Verify critical tools:**
    ```bash
    node --version
    python --version
    git --version
    terraform --version
    kubectl version --client
    ```

19. **Check shell startup time:**
    ```bash
    time zsh -i -c exit
    # Should be < 300ms
    ```

20. **Delete `.mise.toml`:**
    ```bash
    rm ~/.mise.toml
    rm ~/.mise.toml.backup  # After 1 week if no issues
    ```

---

## 8. Testing Strategy

### 8.1 Smoke Tests

Create `smoke-test.sh`:

```bash
#!/bin/bash
# smoke-test.sh - Quick validation of critical tools

set -e

echo "=== Smoke Test Suite ==="
echo ""

# Test 1: Devbox is active
echo "Test 1: Devbox global environment"
if devbox global list &> /dev/null; then
    echo "✅ Devbox global is active"
else
    echo "❌ Devbox global not working"
    exit 1
fi

# Test 2: Critical tools work
echo ""
echo "Test 2: Critical development tools"
for tool in node python git jq terraform kubectl; do
    if command -v $tool &> /dev/null; then
        version=$($tool --version 2>&1 | head -n1)
        echo "✅ $tool: $version"
    else
        echo "❌ $tool not found"
        exit 1
    fi
done

# Test 3: Tools are from devbox/nix
echo ""
echo "Test 3: Tool paths (should be from devbox/nix)"
for tool in node python git jq; do
    path=$(which $tool)
    if [[ "$path" == *"devbox"* ]] || [[ "$path" == *"nix"* ]]; then
        echo "✅ $tool: $path"
    else
        echo "⚠️  $tool not from devbox: $path"
    fi
done

# Test 4: Homebrew GUI apps
echo ""
echo "Test 4: Homebrew GUI applications"
for app in "Visual Studio Code" "Google Chrome" "1Password"; do
    if [ -d "/Applications/$app.app" ]; then
        echo "✅ $app installed"
    else
        echo "⚠️  $app not found"
    fi
done

echo ""
echo "=== Smoke tests passed! ==="
```

### 8.2 Integration Tests

Create `integration-test.sh`:

```bash
#!/bin/bash
# integration-test.sh - Comprehensive validation

set -e

echo "=== Integration Test Suite ==="
echo ""

# Test 1: Shell integration
echo "Test 1: Shell environment variables"
if [ -n "$DEVBOX_GLOBAL" ]; then
    echo "✅ DEVBOX_GLOBAL is set: $DEVBOX_GLOBAL"
else
    echo "❌ DEVBOX_GLOBAL not set"
    exit 1
fi

# Test 2: Project-specific devbox
echo ""
echo "Test 2: Project-specific devbox"
tmpdir=$(mktemp -d)
cd "$tmpdir"
devbox init
devbox add go@latest
if devbox run go version; then
    echo "✅ Project devbox works"
else
    echo "❌ Project devbox failed"
    exit 1
fi
cd - > /dev/null
rm -rf "$tmpdir"

# Test 3: Direnv integration
echo ""
echo "Test 3: Direnv integration"
if command -v direnv &> /dev/null; then
    echo "✅ direnv is installed"
else
    echo "❌ direnv not found"
    exit 1
fi

# Test 4: Package count
echo ""
echo "Test 4: Package count"
count=$(devbox global list | wc -l)
if [ $count -ge 90 ]; then
    echo "✅ $count packages installed (expected ~97)"
else
    echo "⚠️  Only $count packages installed (expected ~97)"
fi

echo ""
echo "=== All integration tests passed! ==="
```

### 8.3 Performance Benchmark

```bash
#!/bin/bash
# benchmark.sh - Compare shell startup times

echo "=== Shell Startup Benchmark ==="

total=0
for i in {1..10}; do
    start=$(date +%s%N)
    zsh -i -c exit
    end=$(date +%s%N)
    elapsed=$((($end - $start) / 1000000))
    total=$(($total + $elapsed))
done
avg=$(($total / 10))
echo "Average startup time: ${avg}ms"

if [ $avg -lt 300 ]; then
    echo "✅ Performance is good (< 300ms)"
else
    echo "⚠️  Startup is slow (> 300ms)"
fi
```

---

## 9. Rollback Plan

### 9.1 Quick Rollback (5 minutes)

If issues are discovered immediately:

```bash
#!/bin/bash
# rollback.sh - Quick rollback to mise

echo "=== Rolling back to mise setup ==="

# 1. Restore mise configuration
cp ~/.mise.toml.backup ~/.mise.toml

# 2. Reinstall mise
brew install mise

# 3. Restore shell configuration
cp ~/.zshrc.backup ~/.zshrc

# 4. Reinstall mise tools
mise install

# 5. Reload shell
exec $SHELL -l

echo "✅ Rollback complete - mise is active again"
```

### 9.2 Full Rollback (15 minutes)

If complete revert is needed:

```bash
#!/bin/bash
# full-rollback.sh - Complete rollback

set -e

echo "=== Full rollback to pre-migration state ==="

# 1. Restore all backups
echo "Restoring configuration files..."
cp ~/.mise.toml.backup ~/.mise.toml
cp ~/.zshrc.backup ~/.zshrc
cp ~/Brewfile.backup ~/Brewfile

# 2. Reinstall mise
echo "Reinstalling mise..."
brew install mise

# 3. Restore Homebrew packages
echo "Restoring Homebrew packages..."
brew bundle --file=~/Brewfile.backup

# 4. Remove devbox global configuration
echo "Cleaning up devbox..."
rm -rf ~/.local/share/devbox/global
rm -f ~/.devbox-global.json

# 5. Reinstall mise tools
echo "Reinstalling mise tools..."
mise trust ~/.mise.toml
mise install

# 6. Reload shell
echo "Reloading shell..."
exec $SHELL -l

echo "✅ Full rollback complete"
```

### 9.3 Rollback Decision Matrix

| Issue | Severity | Action | Time |
|-------|----------|--------|------|
| Single tool not working | Low | Fix forward | 5 min |
| Multiple tools broken | Medium | Quick rollback | 5 min |
| Shell won't start | High | Full rollback | 15 min |
| Performance issues | Medium | Investigate first | 30 min |

---

## 10. Post-Migration

### 10.1 Day 1 Checklist

- [ ] All critical development tools work
- [ ] Shell startup time < 300ms
- [ ] No error messages in shell startup
- [ ] Project-specific devbox environments work
- [ ] Homebrew GUI apps launch correctly
- [ ] Git operations work (signing, LFS)
- [ ] Cloud CLI tools authenticate properly

### 10.2 Week 1 Monitoring

| Metric | Target | Check Command |
|--------|--------|---------------|
| Shell startup | < 250ms | `time zsh -i -c exit` |
| Tool availability | 100% | Run smoke tests daily |
| No errors | 0 | Check shell output |

### 10.3 Maintenance Tasks

| Task | Frequency | Command |
|------|-----------|---------|
| Update devbox packages | Weekly | `devbox global update` |
| Clean Nix store | Monthly | `nix-collect-garbage -d` |
| Update Homebrew | Weekly | `brew update && brew upgrade` |
| Backup configuration | Monthly | `cp ~/.devbox-global.json ~/backup/` |

### 10.4 Common Issues & Solutions

#### Issue 1: Tool not found

**Solution:**
```bash
devbox global list | grep <tool>
devbox global add <tool>
exec $SHELL -l
```

#### Issue 2: Wrong version

**Solution:**
```bash
vim ~/.devbox-global.json  # Update version
devbox global pull ~/.devbox-global.json
exec $SHELL -l
```

#### Issue 3: Slow startup

**Solution:**
```bash
zsh -i -c 'zprof'  # Profile startup
devbox global install --force  # Rebuild
```

---

## 11. Success Criteria

- ✅ All development tools work correctly
- ✅ Shell startup time < 300ms
- ✅ No breaking changes to existing workflows
- ✅ Team can onboard new members easily
- ✅ Rollback plan tested and documented

---

## 12. Next Steps

1. **Review this plan** - Ensure all changes are understood
2. **Ask questions** - Clarify any unclear sections
3. **Approve migration** - Give go-ahead to proceed
4. **Switch to Code mode** - Implement the changes
5. **Execute migration** - Follow steps in section 7
6. **Validate** - Run all tests in section 8
7. **Monitor** - Track metrics for 1 week

---

**Ready to proceed?** If approved, switch to Code mode to implement these changes.