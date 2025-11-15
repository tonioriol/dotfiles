# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don't want to commit.
for file in ~/.{path,zsh_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH"

# Case-insensitive globbing (used in pathname expansion)
setopt NO_CASE_GLOB

# Append to the zsh history file, rather than overwriting it
setopt APPEND_HISTORY

# Share history across all sessions
setopt SHARE_HISTORY

# Autocorrect typos in path names when using `cd`
setopt CORRECT
setopt CORRECT_ALL

# Enable extended globbing (recursive globbing with **)
setopt EXTENDED_GLOB

# Auto cd when typing just a path
setopt AUTO_CD

# Zsh completions (installed via brew: zsh-completions)
if type brew &>/dev/null; then
	FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
	FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
	
	# Initialize completion system
	# Use -u flag to skip insecure directory checks (Homebrew directories are safe)
	# This prevents the "insecure directories" warning on fresh installations
	autoload -Uz compinit
	compinit -u
	
	# Load zsh-autosuggestions (Fish-like suggestions)
	if [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
		source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
	fi
	
	# Load zsh-syntax-highlighting (Fish-like syntax highlighting) - MUST BE LAST
	if [ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
		source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
	fi
fi

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &>/dev/null; then
	compdef g=git
fi

# mise - Modern version manager (replaces asdf, nvm, pyenv, rbenv, etc.)
# Faster Rust-based alternative with better UX
# Install languages: mise use --global node@lts python@latest ruby@latest
# See: https://mise.jdx.dev/
if type mise &>/dev/null; then
	eval "$(mise activate zsh)"
fi

# direnv - Automatically load/unload environment variables based on directory
# Loads .envrc files when entering directories, unloads when leaving
# Run 'direnv allow' after creating/editing .envrc files
if type direnv &>/dev/null; then
	eval "$(direnv hook zsh)"
fi

# zoxide - Smarter cd command (learns your habits)
# Usage: z <partial-path> to jump to frequently used directories
if type zoxide &>/dev/null; then
	eval "$(zoxide init zsh)"
fi

# McFly - smart history search (if installed via brew)
if type mcfly &>/dev/null; then
	eval "$(mcfly init zsh)"
fi

# FZF - fuzzy finder (Ctrl+R for history, Ctrl+T for files)
if type brew &>/dev/null; then
	if [ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ]; then
		source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
	fi
	if [ -f "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ]; then
		source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
	fi
fi

# GPG TTY (for commit signing)
export GPG_TTY=$(tty)