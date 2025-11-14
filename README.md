# tr0n's Mathias’s dotfiles

![Screenshot of my shell prompt](https://i.imgur.com/EkEtphC.png)

## Installation

**Warning:** If you want to give these dotfiles a try, you should first fork this repository, review the code, and remove things you don’t want or need. Don’t blindly use my settings unless you know what that entails. Use at your own risk!

### Using Git and the bootstrap script

You can clone the repository wherever you want. (I like to keep it in `~/Projects/dotfiles`, with `~/dotfiles` as a symlink.) The bootstrapper script will pull in the latest version and copy the files to your home folder.

```bash
git clone https://github.com/tonioriol/dotfiles.git && cd dotfiles && source bootstrap.sh
```

To update, `cd` into your local `dotfiles` repository and then:

```bash
source bootstrap.sh
```

Alternatively, to update while avoiding the confirmation prompt:

```bash
set -- -f; source bootstrap.sh
```

### Git-free install

To install these dotfiles without Git:

```bash
cd; curl -#L https://github.com/tonioriol/dotfiles/tarball/master | tar -xzv --strip-components 1 --exclude={README.md,bootstrap.sh,.osx,LICENSE-MIT.txt}
```

To update later on, just run that command again.

### Specify the `$PATH`

If `~/.path` exists, it will be sourced along with the other files, before any feature testing (such as detecting which version of `ls` is being used) takes place.

Here’s an example `~/.path` file that adds `/usr/local/bin` to the `$PATH`:

```bash
export PATH="/usr/local/bin:$PATH"
```

### Add custom commands without creating a new fork

If `~/.extra` exists, it will be sourced along with the other files. You can use this to add a few custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.

My `~/.extra` looks something like this:

```bash
# Git credentials
# Not in the repository, to prevent people from accidentally committing under my name
GIT_AUTHOR_NAME="Mathias Bynens"
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "$GIT_AUTHOR_NAME"
GIT_AUTHOR_EMAIL="mathias@mailinator.com"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "$GIT_AUTHOR_EMAIL"
```

You could also use `~/.extra` to override settings, functions and aliases from my dotfiles repository. It’s probably better to fork this repo instead, though.

### Sensible macOS defaults

When setting up a new Mac, you may want to set some sensible macOS defaults:

```bash
./.macos
```

### Install Homebrew formulae

When setting up a new Mac, you may want to install some common [Homebrew](https://brew.sh/) formulae (after installing Homebrew, of course):

```bash
./brew.sh
```

This will install all packages and automatically set up:
- **mise** - Modern version manager (replaces asdf)
- **Node.js LTS** - Installed via mise (configured in `.mise.toml`)
- **Python 3.12** - Installed via mise (configured in `.mise.toml`)

After installation, reload your shell:
```bash
exec $SHELL -l
```

### Customizing mise tools

Edit `.mise.toml` to add or remove development tools. Uncomment any tools you need:

```bash
# Edit the configuration
vim .mise.toml

# Install tools from .mise.toml
mise install

# Or install individual tools
mise use --global ruby@latest
mise use --global terraform@latest
mise use --global kubectl@latest
```

Available tools include: Node.js, Python, Ruby, Go, Rust, Java, Terraform, kubectl, Helm, AWS CLI, Maven, Deno, and many more. See [mise registry](https://mise.jdx.dev/registry.html) for the full list.

Some of the functionality of these dotfiles depends on formulae installed by `brew.sh`. If you don't plan to run `brew.sh`, you should look carefully through the script and manually install any particularly important ones.

## Apple Silicon Notes

These dotfiles are optimized for Apple Silicon (M1/M2/M3/M4) Macs:
- Homebrew paths use `$(brew --prefix)` for cross-architecture compatibility
- Python 3 is used throughout (Python 2 removed)
- Modern CLI tools included (bat, eza, delta, zoxide, lazygit, etc.)
- **colima** - Lightweight Docker runtime optimized for Apple Silicon (alternative to Docker Desktop)
- **devbox** - Reproducible development environments powered by Nix for project-specific tooling
- See `APPLE_SILICON_REVIEW.md` for detailed changes and recommendations

## Notes & migration

This fork has been customized to help migrating to a new Mac while keeping sensitive credentials out of git. Recommended workflow:

- Run the staged secrets helper script included in `scripts/stage_secrets.sh` on your source machine. That script copies sensitive files into `./.secrets_staging/` (which is gitignored) and sets strict permissions. Do NOT commit `.secrets_staging/`.
- Use this repo's `bootstrap.sh` after reviewing and cleaning the files you want to install. The bootstrap script will rsync files into your home directory.
- The `brew.sh` script in this repo can be regenerated from the source machine to produce an exact list of formulae & casks.

## Feedback

Suggestions/improvements
[welcome](https://github.com/tonioriol/dotfiles/issues)!

## Author

Forked form the amazing https://github.com/mathiasbynens/dotfiles

## TODO
copy dev fonts
review all improved cli tools we added, and checek if we can make them default, like ls, cat, git diff, etc.