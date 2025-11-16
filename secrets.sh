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
  
  # GPG (entire directory - includes all keys, config, trust)
  ["gnupg"]="${HOME}/.gnupg:700:"
  
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

  # Backup regular files
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
      
      # Copy files (may produce errors for sockets which we can ignore)
      cp -a "$file" "$backup_path" 2>/dev/null || true
      chmod -R go-rwx "$(dirname "$backup_path")" 2>/dev/null || true
      
      # Verify backup succeeded by checking if destination exists
      if [[ -e "$backup_path" ]]; then
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

  # Restore regular files
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
  if command -v gpg &> /dev/null && gpg --list-secret-keys &> /dev/null 2>&1; then
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
    gpg --list-secret-keys --keyid-format=long 2>/dev/null || {
      echo "Note: Run 'gpg --list-secret-keys --keyid-format=long' to see your keys"
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