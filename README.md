# tr0n's Mathias’s dotfiles

![Screenshot of my shell prompt](https://i.imgur.com/EkEtphC.png)

## Installation

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

### Using Git and the bootstrap script

You can clone the repository wherever you want. (I like to keep it in `~/Projects/dotfiles`, with `~/dotfiles` as a symlink.) The bootstrapper script will pull in the latest version and copy the files to your home folder.

```shell
git clone https://github.com/tonioriol/dotfiles.git && cd dotfiles && source bootstrap.sh
```

To update, `cd` into your local `dotfiles` repository and then:

```shell
source bootstrap.sh
```

Alternatively, to update while avoiding the confirmation prompt:

```shell
set -- -f; source bootstrap.sh
```

### Git-free install

To install these dotfiles without Git:

```shell
cd; curl -#L https://github.com/tonioriol/dotfiles/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,bootstrap.sh,.macos,LICENSE-MIT.txt}
```

To update later on, just run that command again.

### Specify the `$PATH`

If `~/.path` exists, it will be sourced along with the other files, before any feature testing (such as detecting which version of `ls` is being used) takes place.

Here’s an example `~/.path` file that adds `/usr/local/bin` to the `$PATH`:

```shell
export PATH="/usr/local/bin:$PATH"
```

### Personalization with `.extra`

The `.extra` file (gitignored) contains your personal configuration:

```shell
cp .extra.template ~/.extra
vim ~/.extra  # Edit with your personal information
```

See `.extra.template` for full documentation on all available options (git credentials, macOS settings, editor preferences, etc.).

### Additional Setup

**macOS defaults:** `./.macos` - Configure sensible macOS system settings

**Homebrew packages:** `./brew.sh` - Install packages including mise, which manages Node.js and Python versions (see `.mise.toml`)
  - The bootstrap script automatically trusts the `.mise.toml` configuration file
  - Tools defined in `.mise.toml` are installed automatically during setup

**Customize tools:** Edit `.mise.toml` to add/remove development tools. See [mise registry](https://mise.jdx.dev/registry.html) for available tools.

## Apple Silicon Notes

These dotfiles are optimized for Apple Silicon (M1/M2/M3/M4) Macs:
- Homebrew paths use `$(brew --prefix)` for cross-architecture compatibility
- Python 3 is used throughout (Python 2 removed)
- Modern CLI tools included (bat, eza, delta, zoxide, lazygit, etc.)
- **colima** - Lightweight Docker runtime optimized for Apple Silicon (alternative to Docker Desktop)
- **devbox** - Reproducible development environments powered by Nix for project-specific tooling
- See `APPLE_SILICON_REVIEW.md` for detailed changes and recommendations

## Modern CLI Tools

Modern replacements for Unix commands (installed via `brew.sh`):
- **eza** → `ls`, **bat** → `cat`, **delta** → `git diff`, **fd** → `find`, **ripgrep** → `grep`
- **duf** → `df`, **dust** → `du`, **procs** → `ps`, **bottom** → `top`

Use `\command` or `command command` to access originals if needed.

## Notes & migration

This fork has been customized to help migrating to a new Mac while keeping sensitive credentials out of git. Recommended workflow:

### On your source machine:
1. Run the secrets backup script to save sensitive files:
   ```shell
   ./scripts/secrets.sh backup
   ```
   This copies sensitive files (SSH keys, AWS credentials, GPG keys, etc.) into `./.secrets/` (which is gitignored) and sets strict permissions. Do NOT commit `.secrets/`.

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
   This will sync dotfiles, install packages, and configure macOS settings.

5. Restore your secrets:
   ```shell
   ./scripts/secrets.sh restore
   ```

6. If you use GPG signing, add your key ID to `~/.extra`:
   ```shell
   # Get your GPG key ID
   gpg --list-secret-keys --keyid-format=long
   
   # Edit ~/.extra and uncomment the GPG lines with your key ID
   vim ~/.extra
   
   # Reload configuration
   source ~/.extra
   ```

7. Restart your computer for all macOS settings to take effect

### Regenerating brew.sh
The `brew.sh` script can be regenerated from your source machine to produce an exact list of formulae & casks:
```shell
# On source machine, generate list of installed packages
brew bundle dump --describe --force
```

## Feedback

Suggestions/improvements
[welcome](https://github.com/tonioriol/dotfiles/issues)!

## Author

Forked from the amazing https://github.com/mathiasbynens/dotfiles
