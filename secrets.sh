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
      
      if cp -a "$file" "$backup_path"; then
        chmod -R go-rwx "$(dirname "$backup_path")"
        echo "✓ $file"
      else
        echo "✗ $file (failed)"
      fi
    done
  done
  
  # Special handling for GPG keys - use proper export commands
  if command -v gpg &> /dev/null && gpg --list-secret-keys &> /dev/null; then
    echo ""
    echo "Exporting GPG keys..."
    mkdir -p "$DEST/gpg"
    chmod 700 "$DEST/gpg"
    
    # Export all public keys
    if gpg --export --armor > "$DEST/gpg/public-keys.asc" 2>/dev/null; then
      chmod 600 "$DEST/gpg/public-keys.asc"
      echo "✓ GPG public keys exported"
    else
      echo "⊘ No GPG public keys found"
      rm -f "$DEST/gpg/public-keys.asc"
    fi
    
    # Export all private keys
    if gpg --export-secret-keys --armor > "$DEST/gpg/private-keys.asc" 2>/dev/null; then
      chmod 600 "$DEST/gpg/private-keys.asc"
      echo "✓ GPG private keys exported"
    else
      echo "⊘ No GPG private keys found"
      rm -f "$DEST/gpg/private-keys.asc"
    fi
    
    # Export owner trust
    if gpg --export-ownertrust > "$DEST/gpg/ownertrust.txt" 2>/dev/null; then
      chmod 600 "$DEST/gpg/ownertrust.txt"
      echo "✓ GPG owner trust exported"
    else
      echo "⊘ No GPG owner trust found"
      rm -f "$DEST/gpg/ownertrust.txt"
    fi
  else
    echo "⊘ GPG not available or no keys found"
  fi
  
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
    # Skip GPG directory (handled separately below)
    if [[ "$backup_file" == "$DEST/gpg" ]] || [[ "$backup_file" == "$DEST/gpg/"* ]]; then
      continue
    fi
    
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
  
  # Special handling for GPG keys - use proper import commands
  if [[ -d "$DEST/gpg" ]] && command -v gpg &> /dev/null; then
    echo ""
    echo "Importing GPG keys..."
    
    # Import public keys
    if [[ -f "$DEST/gpg/public-keys.asc" ]]; then
      if gpg --import "$DEST/gpg/public-keys.asc" 2>&1 | grep -q "imported\|unchanged"; then
        echo "✓ GPG public keys imported"
      else
        echo "⊘ Failed to import GPG public keys"
      fi
    fi
    
    # Import private keys
    if [[ -f "$DEST/gpg/private-keys.asc" ]]; then
      if gpg --import "$DEST/gpg/private-keys.asc" 2>&1 | grep -q "imported\|unchanged\|secret key"; then
        echo "✓ GPG private keys imported"
      else
        echo "⊘ Failed to import GPG private keys"
      fi
    fi
    
    # Import owner trust
    if [[ -f "$DEST/gpg/ownertrust.txt" ]]; then
      if gpg --import-ownertrust "$DEST/gpg/ownertrust.txt" 2>&1 | grep -q "inserted\|processed"; then
        echo "✓ GPG owner trust imported"
      else
        echo "⊘ Failed to import GPG owner trust"
      fi
    fi
  fi
  
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