#!/usr/bin/env bash
# Backup and restore secrets
# Notes:
# - Backups go to .secrets/ (gitignored)

set -euo pipefail

DEST="${PWD}/.secrets"
FAILED_ITEMS=()

# Define what to backup/restore (format: "source_path:destination_subdir")
declare -A BACKUP_ITEMS=(
  ["ssh"]="${HOME}/.ssh:ssh"
  ["aws"]="${HOME}/.aws:aws"
  ["netrc"]="${HOME}/.netrc:configs"
  ["npmrc"]="${HOME}/.npmrc:configs"
  ["gitconfig"]="${HOME}/.gitconfig:configs"
  ["docker"]="${HOME}/.docker/config.json:configs/docker"
  ["kube"]="${HOME}/.kube/config:configs/kube"
  ["gh"]="${HOME}/.config/gh:configs/gh"
  ["glab"]="${HOME}/.config/glab-cli:configs/glab-cli"
  ["linear"]="${HOME}/.config/linear-cli:configs/linear-cli"
  ["gh-copilot"]="${HOME}/.config/gh-copilot:configs/gh-copilot"
  ["firebase"]="${HOME}/.config/configstore/firebase-tools.json:configs/configstore"
  ["gcloud"]="${HOME}/.config/gcloud:configs/gcloud"
  ["azure"]="${HOME}/.azure:configs/azure"
  ["doctl"]="${HOME}/Library/Application Support/doctl:configs/doctl"
  ["terraform"]="${HOME}/.terraform.d:configs/terraform"
)

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

  # Backup all defined items
  for key in "${!BACKUP_ITEMS[@]}"; do
    IFS=':' read -r src dest <<< "${BACKUP_ITEMS[$key]}"
    copy "$src" "$DEST/$dest"
  done
  
  # GPG requires special handling (export instead of copy)
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

  # Restore all defined items
  for key in "${!BACKUP_ITEMS[@]}"; do
    IFS=':' read -r src dest <<< "${BACKUP_ITEMS[$key]}"
    backup_path="$DEST/$dest"
    
    # Determine the actual backed up path (handle directory vs file)
    if [[ -d "$backup_path" ]]; then
      # For directories, the backup contains the directory itself
      actual_backup=$(find "$backup_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
      [[ -n "$actual_backup" ]] && restore "$actual_backup" "$src"
    elif [[ -f "$backup_path/$(basename "$src")" ]]; then
      # For files, restore from the backup directory
      restore "$backup_path/$(basename "$src")" "$src"
    fi
  done
  
  # Apply special permissions for SSH and AWS
  if [[ -d "${HOME}/.ssh" ]]; then
    chmod 700 "${HOME}/.ssh" 2>/dev/null || true
    chmod 600 "${HOME}/.ssh"/id_* 2>/dev/null || true
  fi
  if [[ -d "${HOME}/.aws" ]]; then
    chmod 700 "${HOME}/.aws" 2>/dev/null || true
    chmod 600 "${HOME}/.aws"/* 2>/dev/null || true
  fi
  
  # GPG requires special handling (import instead of copy)
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