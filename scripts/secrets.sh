#!/usr/bin/env bash
# Backup and restore secrets
# Notes:
# - Backups go to .secrets/ (gitignored)

set -euo pipefail

DEST="${PWD}/.secrets"

[[ $# -eq 0 ]] && echo "Usage: $0 <backup|restore>" && exit 1

# ============================================================================
# BACKUP
# ============================================================================
if [[ "$1" == "backup" ]]; then
  echo "Backing up to $DEST"
  mkdir -p "$DEST" && chmod 700 "$DEST"

  copy() {
    [[ ! -e "$1" ]] && return
    mkdir -p "$2" && cp -a "$1" "$2/" && chmod -R go-rwx "$2"
    echo "✓ $1"
  }

  copy "${HOME}/.ssh" "$DEST/ssh"
  copy "${HOME}/.aws" "$DEST/aws"
  
  if command -v gpg >/dev/null 2>&1; then
    mkdir -p "$DEST/gpg"
    gpg --export-secret-keys --armor > "$DEST/gpg/private.asc" 2>/dev/null || true
    gpg --export --armor > "$DEST/gpg/public.asc" 2>/dev/null || true
    gpg --export-ownertrust > "$DEST/gpg/trust.txt" 2>/dev/null || true
    echo "✓ GPG"
  fi
  
  copy "${HOME}/Library/Application Support/Firefox/Profiles" "$DEST/firefox"
  copy "${HOME}/Library/Application Support/zen/Profiles" "$DEST/zen"
  copy "${HOME}/Library/Application Support/Google/Chrome" "$DEST/chrome"
  
  for f in .netrc .npmrc .gitconfig; do
    copy "${HOME}/$f" "$DEST/configs"
  done
  copy "${HOME}/.docker/config.json" "$DEST/configs/docker"
  copy "${HOME}/.kube/config" "$DEST/configs/kube"
  copy "${HOME}/.config/gh" "$DEST/configs/gh"
  
  for d in "${HOME}/Library/Application Support/JetBrains" \
           "${HOME}/Library/Application Support/IntelliJIdea"; do
    [[ -d "$d" ]] && copy "$d" "$DEST/intellij" && break
  done
  
  echo "Done!"

# ============================================================================
# RESTORE
# ============================================================================
elif [[ "$1" == "restore" ]]; then
  [[ ! -d "$DEST" ]] && echo "Error: $DEST not found" && exit 1
  echo "Restoring from $DEST"

  restore() {
    [[ ! -e "$1" ]] && return
    mkdir -p "$(dirname "$2")" && cp -a "$1" "$2"
    echo "✓ $2"
  }

  [[ -d "$DEST/ssh/.ssh" ]] && restore "$DEST/ssh/.ssh" "${HOME}/.ssh" && chmod 700 "${HOME}/.ssh" && chmod 600 "${HOME}/.ssh"/id_* 2>/dev/null || true
  [[ -d "$DEST/aws/.aws" ]] && restore "$DEST/aws/.aws" "${HOME}/.aws" && chmod 700 "${HOME}/.aws" && chmod 600 "${HOME}/.aws"/* 2>/dev/null || true
  
  if [[ -f "$DEST/gpg/private.asc" ]]; then
    gpg --import "$DEST/gpg/private.asc" 2>/dev/null || true
    gpg --import "$DEST/gpg/public.asc" 2>/dev/null || true
    gpg --import-ownertrust "$DEST/gpg/trust.txt" 2>/dev/null || true
    echo "✓ GPG"
  fi
  
  [[ -d "$DEST/firefox/Profiles" ]] && restore "$DEST/firefox/Profiles" "${HOME}/Library/Application Support/Firefox/Profiles"
  [[ -d "$DEST/zen/Profiles" ]] && restore "$DEST/zen/Profiles" "${HOME}/Library/Application Support/zen/Profiles"
  [[ -d "$DEST/chrome/Chrome" ]] && restore "$DEST/chrome/Chrome" "${HOME}/Library/Application Support/Google/Chrome"
  
  for f in .netrc .npmrc .gitconfig; do
    [[ -f "$DEST/configs/$f" ]] && restore "$DEST/configs/$f" "${HOME}/$f"
  done
  [[ -f "$DEST/configs/docker/config.json" ]] && restore "$DEST/configs/docker/config.json" "${HOME}/.docker/config.json"
  [[ -f "$DEST/configs/kube/config" ]] && restore "$DEST/configs/kube/config" "${HOME}/.kube/config"
  [[ -d "$DEST/configs/gh" ]] && restore "$DEST/configs/gh" "${HOME}/.config/gh"
  
  for d in JetBrains IntelliJIdea; do
    [[ -d "$DEST/intellij/$d" ]] && restore "$DEST/intellij/$d" "${HOME}/Library/Application Support/$d" && break
  done
  
  echo "Done!"

else
  echo "Usage: $0 <backup|restore>" && exit 1
fi