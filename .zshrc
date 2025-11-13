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
	
	autoload -Uz compinit
	compinit
	
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

# ASDF version manager (replaces nvm, pyenv, rbenv, etc.)
# Install plugins: asdf plugin add nodejs python ruby golang rust java
# Then: asdf install nodejs latest && asdf global nodejs latest
if type brew &>/dev/null && [ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]; then
	. "$(brew --prefix asdf)/libexec/asdf.sh"
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