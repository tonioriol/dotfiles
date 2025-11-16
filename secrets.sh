#!/usr/bin/env bash
# Backup and restore sensitive credentials and configurations
# Usage: ./secrets.sh <backup|restore>
# Destination: .secrets/ directory (gitignored, chmod 700)
# Platform: macOS only (uses macOS-specific paths)

set -euo pipefail

DEST="${PWD}/.secrets"

# Define what to backup/restore
# Format: ["key"]="source_path:dir_perm:file_perm"
# Files are stored in .secrets/ mirroring their full path from HOME
declare -A BACKUP_ITEMS=(
  # SSH Keys
  ["ssh-private-keys"]="${HOME}/.ssh/id_*::600"
  ["ssh-public-keys"]="${HOME}/.ssh/id_*.pub::644"
  
  # GPG Keys (both private keys and public keyring needed)
  ["gpg-private-keys"]="${HOME}/.gnupg/private-keys*:700:600"
  ["gpg-public-keyring"]="${HOME}/.gnupg/pubring.kbx::600"
  ["gpg-trustdb"]="${HOME}/.gnupg/trustdb.gpg::600"
  
  # AWS Credentials
  ["aws-credentials"]="${HOME}/.aws/credentials::600"
  ["aws-config"]="${HOME}/.aws/config::600"
  
  # API Tokens
  ["netrc"]="${HOME}/.netrc::600"
  ["npmrc"]="${HOME}/.npmrc::600"
  
  # Tool Credentials
  ["linear"]="${HOME}/.config/linear-cli:700:"
  ["firebase"]="${HOME}/.config/firebase:700:600"
  ["doctl"]="${HOME}/Library/Application Support/doctl:700:"
  
  # Fonts (Operator Mono - paid font not in Homebrew)
  ["operator-mono-fonts"]="${HOME}/Library/Fonts/OperatorMono*.otf::644"
)

[[ $# -eq 0 ]] && echo "Usage: $0 <backup|restore>" && exit 1

# ============================================================================
# BACKUP
# ============================================================================
if [[ "$1" == "backup" ]]; then
  echo "Backing up to $DEST"
  mkdir -p "$DEST" && chmod 700 "$DEST"

  for key in "${!BACKUP_ITEMS[@]}"; do
    IFS=':' read -r src _ _ <<< "${BACKUP_ITEMS[$key]}"
    
    # Expand glob patterns
    shopt -s nullglob
    files=()
    while IFS= read -r -d '' file; do
      files+=("$file")
    done < <(compgen -G "$src" -o filenames | tr '\n' '\0')
    shopt -u nullglob
    
    if [[ ${#files[@]} -eq 0 ]]; then
      echo "⊘ $src (not found)"
      continue
    fi
    
    for file in "${files[@]}"; do
      # Store with full path from HOME
      rel_path="${file#$HOME/}"
      backup_path="$DEST/$rel_path"
      mkdir -p "$(dirname "$backup_path")"
      
      if cp -a "$file" "$backup_path"; then
        chmod -R go-rwx "$(dirname "$backup_path")"
        echo "✓ $file"
      else
        echo "✗ $file (failed)"
      fi
    done
  done
  
  echo "Done!"

# ============================================================================
# RESTORE
# ============================================================================
elif [[ "$1" == "restore" ]]; then
  [[ ! -d "$DEST" ]] && echo "Error: $DEST not found" && exit 1
  echo "Restoring from $DEST"

  # Mirror the backup structure back to HOME
  shopt -s dotglob globstar
  for backup_file in "$DEST"/**/*; do
    if [[ ! -f "$backup_file" ]]; then
      continue
    fi
    
    # Calculate target path
    rel_path="${backup_file#$DEST/}"
    target="$HOME/$rel_path"
    
    # Restore file
    mkdir -p "$(dirname "$target")"
    if cp -a "$backup_file" "$target"; then
      echo "✓ $target"
      
      # Apply permissions from BACKUP_ITEMS
      for key in "${!BACKUP_ITEMS[@]}"; do
        IFS=':' read -r src dir_perm file_perm <<< "${BACKUP_ITEMS[$key]}"
        
        # Check if this file matches the pattern
        if [[ "$src" == *"*"* ]]; then
          # Glob pattern - check if rel_path matches
          if [[ "$rel_path" == ${src#$HOME/} ]]; then
            if [[ -n "$file_perm" ]]; then
              chmod "$file_perm" "$target" 2>/dev/null
            fi
            break
          fi
        else
          # Exact path - check if target matches
          if [[ "$target" == "$src" ]]; then
            if [[ -n "$file_perm" ]]; then
              chmod "$file_perm" "$target" 2>/dev/null
            fi
            break
          fi
        fi
      done
    else
      echo "✗ $target (failed)"
    fi
  done
  shopt -u dotglob globstar
  
  echo "Done!"
  
  # ============================================================================
  # POST-RESTORE: GPG KEY DETECTION
  # ============================================================================
  # Check if GPG keys were restored and help user configure .extra
  if [[ -d "$HOME/.gnupg/private-keys-v1.d" ]] && [[ -n "$(ls -A "$HOME/.gnupg/private-keys-v1.d" 2>/dev/null)" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "GPG Keys Detected"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "GPG private keys have been restored. To use them for Git commit signing,"
    echo "you need to add your GPG key ID to ~/.extra file."
    echo ""
    echo "Available GPG keys:"
    echo ""
    
    # List GPG keys with formatting
    gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -A 2 "^sec" || {
      echo "Note: Run 'gpg --list-secret-keys --keyid-format=long' to see your keys"
      echo "      after GPG has initialized (may require first use)"
    }
    
    echo ""
    echo "To configure Git signing:"
    echo "  1. Copy your GPG key ID from above (the part after 'rsa4096/' or similar)"
    echo "  2. Edit ~/.extra and uncomment the GPG configuration lines"
    echo "  3. Replace YOUR_GPG_KEY_ID with your actual key ID"
    echo "  4. Source the file: source ~/.extra"
    echo ""
    echo "Example:"
    echo "  GIT_GPG_KEY=\"ABCD1234EFGH5678\""
    echo "  git config --global user.signingkey \"\$GIT_GPG_KEY\""
    echo ""
  fi

else
  echo "Usage: $0 <backup|restore>" && exit 1
fi