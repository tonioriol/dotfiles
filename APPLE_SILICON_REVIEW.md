# macOS Apple Silicon Dotfiles Review & Recommendations

**Review Date:** 2025-11-13  
**Target:** macOS Sequoia on Apple Silicon (M1/M2/M3/M4)

## 🔴 Critical Issues Requiring Immediate Fixes

### 1. **Homebrew Path Issues** (`.path`)
**Problem:** Hardcoded Intel paths (`/usr/local`) won't work on Apple Silicon.

**Current:**
```bash
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
```

**Fix Required:** Use `$(brew --prefix)` for all paths to support both architectures:
```bash
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
export PATH="$(brew --prefix gnu-sed)/libexec/gnubin:$PATH"
export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"
```

**Apple Silicon Note:** Homebrew installs to `/opt/homebrew` on Apple Silicon vs `/usr/local` on Intel.

---

### 2. **Python 2 Deprecated Code**

#### `.aliases` Line 106
**Problem:** Uses Python 2 `urllib` (removed in Python 3)
```bash
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'
```

**Fix:**
```bash
alias urlencode='python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus(sys.argv[1]))"'
```

#### `.functions` Line 84
**Problem:** Uses Python 2 `SimpleHTTPServer` (removed in Python 3)
```bash
python -c $'import SimpleHTTPServer;...'
```

**Fix:**
```bash
function server() {
    local port="${1:-8000}";
    sleep 1 && open "http://localhost:${port}/" &
    python3 -m http.server "$port";
}
```

---

### 3. **Deprecated macOS Commands** (`.macos`)

#### Line 172: iTunes/Music Media Keys
**Problem:** Path doesn't exist on modern macOS (Catalina+)
```bash
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2> /dev/null || true
```

**Status:** Already has error handling (`|| true`), but won't work. Consider removing or updating for Music.app.

#### Line 708-710: Time Machine Local Snapshots
**Problem:** Uses deprecated `disablelocal` command
```bash
sudo tmutil disable 2>/dev/null || true
```

**Status:** Already updated correctly! ✅

---

## 🟡 Compatibility Warnings

### 1. **`.aliases` - Update Command (Line 52)**
**Problem:** Tries to update npm, Ruby gems globally - may fail with modern security
```bash
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update; sudo gem cleanup'
```

**Recommendation:** Simplify to just Homebrew and system updates:
```bash
alias update='sudo softwareupdate -i -a; brew update; brew upgrade --cleanup'
```

Use `asdf` for language version management instead of global npm/gem.

---

### 2. **`.aliases` - Deprecated Cask Command (Line 150)**
**Problem:** `brew cask` is deprecated since Homebrew 2.6.0 (2020)
```bash
alias cask="brew cask"
```

**Fix:** Remove this alias. Use `brew install --cask` or just `brew install` (auto-detects).

---

### 3. **`.macos` - System Integrity Protection Issues**

Several commands may fail on modern macOS due to SIP:

**Line 67:** LaunchServices register (may require Full Disk Access)
**Line 346:** Unhiding ~/Library (works but xattr may fail silently)
**Line 349:** Unhiding /Volumes (requires SIP disable)

**Recommendation:** Add error handling and user warnings.

---

## 🟢 Good Practices Already Implemented

### ✅ `.zshrc` - Modern Shell Configuration
- Uses zsh (macOS default since Catalina)
- Properly loads Homebrew completions
- Includes zsh-autosuggestions and zsh-syntax-highlighting
- ASDF integration for version management
- McFly and FZF integration

### ✅ `brew.sh` - Comprehensive Package List
- Well-documented with comments
- Includes both formulae and casks
- Uses modern Homebrew 4.0+ syntax
- Good selection of Apple Silicon compatible tools

### ✅ `.macos` - System Settings
- Handles both "System Settings" (Ventura+) and "System Preferences"
- Good error handling with `|| true` patterns
- Comprehensive macOS customization

---

## 📦 Recommended Package Updates

### Add These Modern Tools:

```bash
# Modern CLI tools
bat              # Better cat with syntax highlighting
eza              # Modern ls replacement (successor to exa)
zoxide           # Smarter cd command
delta            # Better git diff viewer
lazygit          # Terminal UI for git
lazydocker       # Terminal UI for docker

# Development
mise             # Alternative to asdf (faster, Rust-based)
devbox           # Reproducible dev environments
direnv           # Per-directory environment variables

# Apple Silicon Optimized
colima           # Lightweight Docker alternative (better than OrbStack for some)
```

### Consider Removing (if not used):

```bash
# Legacy/Deprecated
ack              # Replaced by ripgrep (already installed)
flycut           # Old clipboard manager (consider Maccy instead)
```

---

## 🔧 Recommended File Updates

### Priority 1: Fix Breaking Issues

1. **Update `.path`** - Fix Homebrew paths for Apple Silicon
2. **Update `.aliases`** - Fix Python 2 code
3. **Update `.functions`** - Fix Python 2 SimpleHTTPServer

### Priority 2: Modernize

4. **Update `.aliases`** - Remove deprecated `brew cask` alias
5. **Update `.aliases`** - Simplify `update` alias
6. **Update `.macos`** - Add warnings for SIP-protected operations

### Priority 3: Enhance

7. **Add `.tool-versions`** - For ASDF version pinning
8. **Add `.envrc`** - For direnv support
9. **Update `brew.sh`** - Add modern CLI tools

---

## 🚀 Quick Fix Script

Create this file as `fix-apple-silicon.sh`:

```bash
#!/usr/bin/env bash
# Quick fixes for Apple Silicon compatibility

echo "Fixing .path for Apple Silicon..."
cat > ~/.path << 'EOF'
# Use brew --prefix for cross-architecture compatibility
export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"
export PATH="$(brew --prefix gnu-sed)/libexec/gnubin:$PATH"
export PATH="$(brew --prefix make)/libexec/gnubin:$PATH"
EOF

echo "Fixing Python 2 code in .aliases..."
sed -i.bak 's/python -c "import sys, urllib as ul; print ul.quote_plus/python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus/' ~/.aliases

echo "Removing deprecated brew cask alias..."
sed -i.bak '/^alias cask="brew cask"$/d' ~/.aliases

echo "Done! Reload your shell with: source ~/.zshrc"
```

---

## 📋 Testing Checklist

After applying fixes, test:

- [ ] `brew doctor` - No warnings
- [ ] `which ls` - Shows GNU coreutils version
- [ ] `python3 --version` - Python 3.x available
- [ ] `urlencode "test string"` - Works without errors
- [ ] `server` - Starts HTTP server on port 8000
- [ ] Git operations work with GPG signing
- [ ] ASDF manages language versions
- [ ] Zsh completions work (try `git <tab>`)

---

## 🎯 Architecture-Specific Notes

### Apple Silicon (M1/M2/M3/M4)
- Homebrew prefix: `/opt/homebrew`
- Native ARM64 binaries (faster)
- Rosetta 2 for Intel-only apps (automatic)
- Better battery life with native apps

### Intel Macs (for reference)
- Homebrew prefix: `/usr/local`
- x86_64 binaries
- No Rosetta needed

### Universal Approach
Always use `$(brew --prefix)` in scripts for compatibility with both architectures.

---

## 📚 Additional Resources

- [Homebrew on Apple Silicon](https://docs.brew.sh/Installation)
- [ASDF Version Manager](https://asdf-vm.com/)
- [macOS Defaults](https://macos-defaults.com/)
- [Awesome macOS Command Line](https://github.com/herrbischoff/awesome-macos-command-line)

---

## 🎬 Next Steps

1. **Backup current dotfiles:** `cp -r ~ ~/dotfiles-backup-$(date +%Y%m%d)`
2. **Apply critical fixes** (Priority 1 items)
3. **Test thoroughly** using checklist above
4. **Gradually add modern tools** (Priority 3 items)
5. **Document your customizations** in `.extra`

---

**Generated by:** Dotfiles Review Tool  
**For:** tr0n's dotfiles (forked from mathiasbynens/dotfiles)