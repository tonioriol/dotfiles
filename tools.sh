#!/usr/bin/env bash
# tools.sh - Install and configure development tools
set -euo pipefail

echo "Installing development tools..."

# Homebrew
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ $(uname -m) == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

BREW_PREFIX="$(brew --prefix)"
if [ ! -w "$BREW_PREFIX" ]; then
    sudo chown -R "$(whoami)" "$BREW_PREFIX"
fi

brew update && brew upgrade
brew bundle install
brew cleanup

if [ -x "${BREW_PREFIX}/bin/bash" ] && ! grep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
    echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells > /dev/null
fi

# Devbox
if ! command -v devbox &> /dev/null; then
    curl -fsSL https://get.jetify.com/devbox | bash
    export PATH="$HOME/.local/bin:$PATH"
fi

eval "$(devbox global shellenv)"

# Direnv
if command -v direnv &> /dev/null; then
    direnv allow ~/.envrc
fi

echo "✓ All tools installed!"