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

### Add custom commands without creating a new fork

If `~/.extra` exists, it will be sourced along with the other files. You can use this to add a few custom commands without the need to fork this entire repository, or to add commands you don’t want to commit to a public repository.

My `~/.extra` looks something like this:

```shell
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

```shell
./.macos
```

### Install Homebrew formulae

When setting up a new Mac, you may want to install some common [Homebrew](https://brew.sh/) formulae (after installing Homebrew, of course):

```shell
./brew.sh
```

This will install all packages and automatically set up:
- **mise** - Modern version manager (replaces asdf)
- **Node.js LTS** - Installed via mise (configured in `.mise.toml`)
- **Python 3.12** - Installed via mise (configured in `.mise.toml`)

After installation, reload your shell:
```shell
exec $SHELL -l
```

### Customizing mise tools

Edit `.mise.toml` to add or remove development tools. Uncomment any tools you need:

```shell
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

## Modern CLI Tools

This dotfiles configuration uses modern CLI tools as defaults for better performance and user experience. All tools are automatically installed via `brew.sh`.

### Replacements

The following modern tools replace traditional Unix commands:

- **[eza](https://github.com/eza-community/eza)** → `ls` - Modern ls replacement with icons, colors, and git integration
- **[bat](https://github.com/sharkdp/bat)** → `cat` - Cat clone with syntax highlighting and git integration
- **[delta](https://github.com/dandavison/delta)** → `git diff` - Better git diffs with syntax highlighting and side-by-side view
- **[fd](https://github.com/sharkdp/fd)** → `find` - Faster, simpler, and more user-friendly find alternative
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** → `grep` - Extremely fast grep alternative that respects .gitignore
- **[duf](https://github.com/muesli/duf)** → `df` - Better disk usage display with colors and graphs
- **[dust](https://github.com/bootandy/dust)** → `du` - More intuitive directory size display
- **[procs](https://github.com/dalance/procs)** → `ps` - Modern process viewer with colors and tree view
- **[bottom](https://github.com/ClementTsang/bottom)** → `top` - Modern system monitor with graphs and customizable interface

### Usage Examples

```shell
# Modern ls with icons and git status
ls -la

# Syntax-highlighted file viewing
cat script.js

# Beautiful git diffs
git diff

# Fast file search
find . -name "*.js"

# Fast content search
grep "TODO" -r .

# Better disk usage
df -h

# Directory size analysis
du -h

# Process monitoring
ps aux
top
```

### Backward Compatibility

Original commands remain accessible if needed:

```shell
# Use backslash to bypass alias
\ls -la
\cat file.txt
\grep pattern file

# Use command builtin
command ls
command cat

# Use full paths
/bin/ls
/bin/cat
```

### Configuration

- **eza**: Configured in `.aliases` with sensible defaults (icons, git, colors)
- **bat**: Theme and style configured via environment variables in `.exports`
- **delta**: Git integration configured in `.gitconfig` with side-by-side diffs
- **ripgrep**: Respects `.gitignore` by default, configured via `.ripgreprc` if present

## Notes & migration

This fork has been customized to help migrating to a new Mac while keeping sensitive credentials out of git. Recommended workflow:

- Run the secrets helper script included in `scripts/secrets.sh` on your source machine. That script copies sensitive files into `./.secrets_staging/` (which is gitignored) and sets strict permissions. Do NOT commit `.secrets_staging/`.
- Use this repo's `bootstrap.sh` after reviewing and cleaning the files you want to install. The bootstrap script will rsync files into your home directory.
- The `brew.sh` script in this repo can be regenerated from the source machine to produce an exact list of formulae & casks.

## Feedback

Suggestions/improvements
[welcome](https://github.com/tonioriol/dotfiles/issues)!

## Author

Forked from the amazing https://github.com/mathiasbynens/dotfiles