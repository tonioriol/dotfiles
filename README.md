# tr0n's dotfiles

![Screenshot of my shell prompt](https://i.imgur.com/EkEtphC.png)

Sensible macOS defaults and shell configuration for developers.

## What's Inside

- **Shell configuration**: Zsh with custom prompt, aliases, and functions
- **Package management**: Declarative setup using `Brewfile` (GUI apps) and `devbox.json` (CLI tools)
- **macOS defaults**: Sensible system settings via `.macos`
- **Migration tools**: Scripts to backup/restore secrets when setting up a new Mac

## Quick Start

**Warning:** Review the code before using. Don't blindly use someone else's settings!

```shell
# Clone and run
git clone https://github.com/tonioriol/dotfiles.git && cd dotfiles

# Create your personal config
cp .extra.template ~/.extra
vim ~/.extra  # Add your git credentials, etc.

# Install everything
./bootstrap.sh
```

This will:
1. Copy dotfiles to your home directory
2. Install Homebrew and GUI apps from `Brewfile`
3. Install CLI tools via devbox
4. Configure macOS settings

Restart your shell: `exec $SHELL -l`

## Package Management

This setup uses a **hybrid approach** for better reproducibility:

### GUI Apps & Fonts → Brewfile (Homebrew Bundle)
Browsers, IDEs, productivity apps

### CLI Tools → devbox.json (Nix)
Tools, languages, utilities

```shell
# Edit devbox.json, then sync
./bootstrap.sh -f
exec $SHELL -l

# Search for packages
devbox search <package-name>
```


## Migrating to a New Mac

### On your old Mac:
```shell
./scripts/secrets.sh backup
```
This saves SSH keys, AWS credentials, GPG keys, etc. to `./.secrets/` (gitignored).

### On your new Mac:
```shell
# 1. Clone repo
git clone https://github.com/tonioriol/dotfiles.git && cd dotfiles

# 2. Copy .secrets/ from backup

# 3. Create .extra
cp .extra.template ~/.extra
vim ~/.extra

# 4. Run bootstrap
./bootstrap.sh

# 5. Restore secrets
./scripts/secrets.sh restore
# The restore script will display your GPG keys if found.
# Edit ~/.extra to add your GPG key ID, then: source ~/.extra

# 6. Restart computer
```

## Customization

### Personal Settings
Edit `~/.extra` (gitignored) for:
- Git credentials
- Editor preferences
- Custom environment variables

See `.extra.template` for all options.

### PATH Modifications
Create `~/.path` to add directories to your PATH:
```shell
export PATH="/usr/local/bin:$PATH"
```

### Modern CLI Tools
Includes modern replacements for Unix commands:
- `eza` → ls
- `bat` → cat
- `delta` → git diff
- `fd` → find
- `ripgrep` → grep
- `duf` → df
- `dust` → du

Use `\command` to access originals if needed.

## Key Files

- `bootstrap.sh` - Main installation script
- `tools.sh` - Installs Homebrew and runs `brew bundle`
- `Brewfile` - Declarative list of GUI apps and fonts
- `devbox.json` - Declarative list of CLI tools
- `.macos` - macOS system settings
- `.zshrc` - Zsh configuration
- `.extra.template` - Template for personal settings

## Feedback

Suggestions/improvements [welcome](https://github.com/tonioriol/dotfiles/issues)!

## Credits

Forked from [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)

