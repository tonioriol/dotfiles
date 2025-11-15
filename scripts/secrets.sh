#!/usr/bin/env bash
# Backup and restore sensitive credentials and configurations
# Usage: ./secrets.sh <backup|restore>
# Destination: .secrets/ directory (gitignored, chmod 700)
# Platform: macOS only (uses macOS-specific paths)

set -euo pipefail

DEST="${PWD}/.secrets"
FAILED_ITEMS=()

# Define what to backup/restore
# Format: ["key"]="source_path:destination_subdir"
declare -A BACKUP_ITEMS=(
  ["ssh"]="${HOME}/.ssh:ssh"
  ["aws"]="${HOME}/.aws:aws"
  ["netrc"]="${HOME}/.netrc:configs"
  ["npmrc"]="${HOME}/.npmrc:configs"
  # ["gitconfig"]="${HOME}/.gitconfig:configs"
  # ["docker"]="${HOME}/.docker/config.json:configs/docker"
  # ["kube"]="${HOME}/.kube/config:configs/kube"
  # ["gh"]="${HOME}/.config/gh:configs"
  # ["glab"]="${HOME}/.config/glab-cli:configs"
  ["linear"]="${HOME}/.config/linear-cli:configs"
  # ["gh-copilot"]="${HOME}/.config/gh-copilot:configs"
  ["firebase"]="${HOME}/.config/configstore/firebase-tools.json:configs/configstore"
  ["doctl"]="${HOME}/Library/Application Support/doctl:configs"
  # ["terraform"]="${HOME}/.terraform.d:configs"
  ["operator-mono-fonts"]="${HOME}/Library/Fonts/OperatorMono-*.otf:fonts"
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
    
    # Special handling for wildcard patterns (like fonts)
    if [[ "$src" == *"*"* ]]; then
      mkdir -p "$DEST/$dest"
      if compgen -G "$src" > /dev/null; then
        for file in $src; do
          if cp -a "$file" "$DEST/$dest/" && chmod -R go-rwx "$DEST/$dest"; then
            echo "✓ $(basename "$file")"
          else
            echo "✗ $(basename "$file") (failed)"
            FAILED_ITEMS+=("$(basename "$file")")
          fi
        done
      else
        echo "⊘ $src (not found)"
      fi
    else
      copy "$src" "$DEST/$dest"
    fi
  done
  
  # GPG keys: export as ASCII-armored files (unencrypted)
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
    
    # Special handling for wildcard patterns (like fonts)
    if [[ "$src" == *"*"* ]]; then
      if [[ -d "$backup_path" ]]; then
        target_dir="$(dirname "$src")"
        mkdir -p "$target_dir"
        for file in "$backup_path"/*; do
          [[ -f "$file" ]] && restore "$file" "$target_dir/$(basename "$file")"
        done
      fi
    # Handle both directory and file backups
    elif [[ -d "$backup_path" ]]; then
      # For directories, the backup contains the directory itself
      actual_backup=$(find "$backup_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
      [[ -n "$actual_backup" ]] && restore "$actual_backup" "$src"
    elif [[ -f "$backup_path/$(basename "$src")" ]]; then
      # For files, restore from the backup directory
      restore "$backup_path/$(basename "$src")" "$src"
    fi
  done
  
  # Set secure permissions for SSH and AWS credentials
  if [[ -d "${HOME}/.ssh" ]]; then
    chmod 700 "${HOME}/.ssh" 2>/dev/null || true
    chmod 600 "${HOME}/.ssh"/id_* 2>/dev/null || true
  fi
  if [[ -d "${HOME}/.aws" ]]; then
    chmod 700 "${HOME}/.aws" 2>/dev/null || true
    chmod 600 "${HOME}/.aws"/* 2>/dev/null || true
  fi
  
  # GPG keys: import from ASCII-armored files
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