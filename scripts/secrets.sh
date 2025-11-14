#!/usr/bin/env bash
# Backup and restore secrets
# Notes:
# - Backups go to .secrets/ (gitignored)

set -euo pipefail

DEST="${PWD}/.secrets"
FAILED_ITEMS=()

[[ $# -eq 0 ]] && echo "Usage: $0 <backup|restore>" && exit 1

# ============================================================================
# BACKUP
# ============================================================================
if [[ "$1" == "backup" ]]; then
  echo "Backing up to $DEST"
  mkdir -p "$DEST" && chmod 700 "$DEST"

  copy() {
    [[ ! -e "$1" ]] && echo "⊘ $1 (not found)" && return
    if mkdir -p "$2" && cp -a "$1" "$2/" && chmod -R go-rwx "$2"; then
      echo "✓ $1"
    else
      echo "✗ $1 (failed)"
      FAILED_ITEMS+=("$1")
    fi
  }

  copy "${HOME}/.ssh" "$DEST/ssh"
  copy "${HOME}/.aws" "$DEST/aws"
  
  if command -v gpg >/dev/null 2>&1; then
    mkdir -p "$DEST/gpg"
    if gpg --export-secret-keys --armor > "$DEST/gpg/private.asc" 2>/dev/null && \
       gpg --export --armor > "$DEST/gpg/public.asc" 2>/dev/null && \
       gpg --export-ownertrust > "$DEST/gpg/trust.txt" 2>/dev/null; then
      echo "✓ GPG"
    else
      echo "✗ GPG (failed)"
      FAILED_ITEMS+=("GPG keys")
    fi
  fi
  
  for f in .netrc .npmrc .gitconfig; do
    copy "${HOME}/$f" "$DEST/configs"
  done
  copy "${HOME}/.docker/config.json" "$DEST/configs/docker"
  copy "${HOME}/.kube/config" "$DEST/configs/kube"
  copy "${HOME}/.config/gh" "$DEST/configs/gh"
  
  # Cloud provider configs
  copy "${HOME}/.config/gcloud" "$DEST/configs/gcloud"
  copy "${HOME}/.azure" "$DEST/configs/azure"
  copy "${HOME}/Library/Application Support/doctl" "$DEST/configs/doctl"
  copy "${HOME}/.terraform.d" "$DEST/configs/terraform"
  
  if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Failed to backup:"
    printf '  - %s\n' "${FAILED_ITEMS[@]}"
    echo ""
  fi
  
  echo "Done!"

# ============================================================================
# RESTORE
# ============================================================================
elif [[ "$1" == "restore" ]]; then
  [[ ! -d "$DEST" ]] && echo "Error: $DEST not found" && exit 1
  echo "Restoring from $DEST"

  restore() {
    [[ ! -e "$1" ]] && echo "⊘ $1 (not found)" && return
    if mkdir -p "$(dirname "$2")" && cp -a "$1" "$2"; then
      echo "✓ $2"
    else
      echo "✗ $2 (failed)"
      FAILED_ITEMS+=("$2")
    fi
  }

  if [[ -d "$DEST/ssh/.ssh" ]]; then
    restore "$DEST/ssh/.ssh" "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh" 2>/dev/null || true
    chmod 600 "${HOME}/.ssh"/id_* 2>/dev/null || true
  fi
  
  if [[ -d "$DEST/aws/.aws" ]]; then
    restore "$DEST/aws/.aws" "${HOME}/.aws"
    chmod 700 "${HOME}/.aws" 2>/dev/null || true
    chmod 600 "${HOME}/.aws"/* 2>/dev/null || true
  fi
  
  if [[ -f "$DEST/gpg/private.asc" ]]; then
    if gpg --import "$DEST/gpg/private.asc" 2>/dev/null && \
       gpg --import "$DEST/gpg/public.asc" 2>/dev/null && \
       gpg --import-ownertrust "$DEST/gpg/trust.txt" 2>/dev/null; then
      echo "✓ GPG"
    else
      echo "✗ GPG (failed)"
      FAILED_ITEMS+=("GPG keys")
    fi
  fi
  
  for f in .netrc .npmrc .gitconfig; do
    [[ -f "$DEST/configs/$f" ]] && restore "$DEST/configs/$f" "${HOME}/$f"
  done
  [[ -f "$DEST/configs/docker/config.json" ]] && restore "$DEST/configs/docker/config.json" "${HOME}/.docker/config.json"
  [[ -f "$DEST/configs/kube/config" ]] && restore "$DEST/configs/kube/config" "${HOME}/.kube/config"
  [[ -d "$DEST/configs/gh" ]] && restore "$DEST/configs/gh" "${HOME}/.config/gh"
  
  # Cloud provider configs
  [[ -d "$DEST/configs/gcloud" ]] && restore "$DEST/configs/gcloud" "${HOME}/.config/gcloud"
  [[ -d "$DEST/configs/azure" ]] && restore "$DEST/configs/azure" "${HOME}/.azure"
  [[ -d "$DEST/configs/doctl" ]] && restore "$DEST/configs/doctl" "${HOME}/Library/Application Support/doctl"
  [[ -d "$DEST/configs/terraform" ]] && restore "$DEST/configs/terraform" "${HOME}/.terraform.d"
  
  if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Failed to restore:"
    printf '  - %s\n' "${FAILED_ITEMS[@]}"
    echo ""
  fi
  
  echo "Done!"

else
  echo "Usage: $0 <backup|restore>" && exit 1
fi