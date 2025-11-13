#!/usr/bin/env bash
# scripts/stage_secrets.sh
# Copy sensitive files into a local, git-ignored staging directory for secure transfer.
#
# Usage:
#   ./scripts/stage_secrets.sh [--dry-run] [--dest ./.secrets_staging] [--no-*]
#
# Default behavior: copies SSH private keys, AWS creds, browser profiles, GPG keys,
# certificates, and various config files with API tokens into ./.secrets_staging
# The script will set restrictive permissions (0700 for dir, 0600 for files) and will NOT git add the files.
#
set -euo pipefail

DEST="${PWD}/.secrets_staging"
DRY_RUN=0

# Color codes for output
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  BOLD=''
  NC=''
fi

# Statistics tracking
FOUND_COUNT=0
MISSING_COUNT=0
TOTAL_SIZE=0

usage() {
  cat <<EOF
stage_secrets.sh - gather private files into a local staging dir (gitignored)

Usage:
  $0 [OPTIONS]

Options:
  --dry-run           Show what would be copied without actually copying
  --dest PATH         Destination directory (default: ./.secrets_staging)
  --no-ssh            Skip SSH keys
  --no-aws            Skip AWS credentials
  --no-intellij       Skip IntelliJ/JetBrains settings
  --no-vpn            Skip VPN configurations
  --no-browsers       Skip browser profiles (Firefox, Chrome, Safari)
  --no-gpg            Skip GPG keys
  --no-certs          Skip certificates and DNIe
  --no-configs        Skip config files (netrc, npmrc, docker, kube, gh)
  -h, --help          Show this help message

By default all categories are included. The staging dir will be created if necessary and will
have permission 700. Files inside will be set to 600. Do NOT commit the staging directory.

Recommended transfer:
  1) Create an encrypted disk image (hdiutil create -encryption -size 500m -fs APFS -volname transfer transfer.dmg)
  2) Mount it and copy contents of .secrets_staging into it
  3) Safely transfer the dmg to the target machine (scp, USB, etc.)
EOF
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --dest) DEST="$2"; shift 2;;
    --no-ssh) NO_SSH=1; shift;;
    --no-aws) NO_AWS=1; shift;;
    --no-intellij) NO_INTELLIJ=1; shift;;
    --no-vpn) NO_VPN=1; shift;;
    --no-browsers) NO_BROWSERS=1; shift;;
    --no-gpg) NO_GPG=1; shift;;
    --no-certs) NO_CERTS=1; shift;;
    --no-configs) NO_CONFIGS=1; shift;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

# Helper function to format file size
format_size() {
  local size=$1
  if [[ $size -lt 1024 ]]; then
    echo "${size}B"
  elif [[ $size -lt 1048576 ]]; then
    echo "$((size / 1024))KB"
  else
    echo "$((size / 1048576))MB"
  fi
}

# Helper function to get directory size
get_dir_size() {
  local path="$1"
  if [[ -d "$path" ]]; then
    du -sk "$path" 2>/dev/null | awk '{print $1 * 1024}' || echo "0"
  elif [[ -f "$path" ]]; then
    stat -f%z "$path" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

# Helper function to count files in directory
count_files() {
  local path="$1"
  local pattern="${2:-*}"
  if [[ -d "$path" ]]; then
    find "$path" -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

# Helper to check and report on a secret category
check_secret() {
  local category="$1"
  local path="$2"
  local description="$3"
  
  if [[ -e "$path" ]]; then
    local size=$(get_dir_size "$path")
    TOTAL_SIZE=$((TOTAL_SIZE + size))
    FOUND_COUNT=$((FOUND_COUNT + 1))
    echo -e "${GREEN}[✓]${NC} ${BOLD}${category}${NC}"
    echo -e "    Found: ${path}"
    echo -e "    ${description}"
    echo -e "    Size: $(format_size $size)"
    return 0
  else
    MISSING_COUNT=$((MISSING_COUNT + 1))
    echo -e "${YELLOW}[✗]${NC} ${BOLD}${category}${NC}"
    echo -e "    Not found: ${path}"
    echo -e "    ${description}"
    return 1
  fi
}

# Helper to copy and set permissions (with dry-run support)
safe_copy() {
  local src="$1"
  local dst_dir="$2"
  local description="${3:-}"
  
  if [[ ! -e "${src}" ]]; then
    return 1
  fi
  
  if [[ $DRY_RUN -eq 1 ]]; then
    return 0
  fi
  
  mkdir -p "${dst_dir}"
  cp -a "${src}" "${dst_dir}/" 2>/dev/null || true
  # Set restrictive perms
  find "${dst_dir}" -type d -exec chmod 700 {} \; 2>/dev/null || true
  find "${dst_dir}" -type f -exec chmod 600 {} \; 2>/dev/null || true
  echo -e "${GREEN}✓${NC} Copied ${src} -> ${dst_dir}"
  return 0
}

# Print header
if [[ $DRY_RUN -eq 1 ]]; then
  echo -e "${BLUE}${BOLD}=== DRY RUN MODE - Scanning for secrets ===${NC}\n"
else
  echo -e "${BLUE}${BOLD}=== Staging secrets to ${DEST} ===${NC}\n"
  mkdir -p "${DEST}"
  chmod 700 "${DEST}"
fi

# ============================================================================
# 1) SSH Keys
# ============================================================================
if [[ -z "${NO_SSH-}" ]]; then
  echo -e "${BOLD}[1/9] SSH Keys${NC}"
  if [[ -d "${HOME}/.ssh" ]]; then
    priv_keys=$(find "${HOME}/.ssh" -type f ! -name "*.pub" ! -name "known_hosts*" ! -name "config" ! -name "authorized_keys" 2>/dev/null | wc -l | tr -d ' ')
    pub_keys=$(count_files "${HOME}/.ssh" "*.pub")
    check_secret "SSH Keys" "${HOME}/.ssh" "Private keys: ${priv_keys}, Public keys: ${pub_keys}"
    safe_copy "${HOME}/.ssh" "${DEST}/ssh"
  else
    check_secret "SSH Keys" "${HOME}/.ssh" "SSH directory not found"
  fi
  echo ""
fi

# ============================================================================
# 2) AWS Credentials
# ============================================================================
if [[ -z "${NO_AWS-}" ]]; then
  echo -e "${BOLD}[2/9] AWS Credentials${NC}"
  if [[ -d "${HOME}/.aws" ]]; then
    profiles=$(grep -c "^\[" "${HOME}/.aws/config" 2>/dev/null || echo "0")
    check_secret "AWS Credentials" "${HOME}/.aws" "Profiles: ${profiles}"
    safe_copy "${HOME}/.aws" "${DEST}/aws"
  else
    check_secret "AWS Credentials" "${HOME}/.aws" "AWS directory not found"
  fi
  echo ""
fi

# ============================================================================
# 3) IntelliJ / JetBrains Settings
# ============================================================================
if [[ -z "${NO_INTELLIJ-}" ]]; then
  echo -e "${BOLD}[3/9] IntelliJ/JetBrains Settings${NC}"
  JB_KNOWN=(
    "${HOME}/Library/Application Support/JetBrains"
    "${HOME}/Library/Preferences/JetBrains"
    "${HOME}/Library/Application Support/IntelliJIdea"
    "${HOME}/Library/Preferences/IntelliJIdea"
    "${HOME}/.IdeaIC"
  )
  found_jb=0
  for d in "${JB_KNOWN[@]}"; do
    if compgen -G "${d}*" >/dev/null 2>&1; then
      check_secret "JetBrains Settings" "${d}" "IDE configuration and plugins"
      safe_copy "${d}" "${DEST}/intellij"
      found_jb=1
      break
    fi
  done
  if [[ $found_jb -eq 0 ]]; then
    MISSING_COUNT=$((MISSING_COUNT + 1))
    echo -e "${YELLOW}[✗]${NC} ${BOLD}JetBrains Settings${NC}"
    echo -e "    Not found in common locations"
  fi
  echo ""
fi

# ============================================================================
# 4) VPN Configurations
# ============================================================================
if [[ -z "${NO_VPN-}" ]]; then
  echo -e "${BOLD}[4/9] VPN Configurations${NC}"
  vpn_found=0
  
  VPN_PATHS=(
    "/etc/openvpn:OpenVPN system configs"
    "${HOME}/Library/Application Support/Tunnelblick:Tunnelblick profiles"
    "${HOME}/Library/Application Support/Viscosity:Viscosity profiles"
    "${HOME}/Library/Application Support/WireGuard:WireGuard configs"
  )
  
  for entry in "${VPN_PATHS[@]}"; do
    IFS=':' read -r path desc <<< "$entry"
    if [[ -e "$path" ]]; then
      check_secret "VPN Config" "$path" "$desc"
      safe_copy "$path" "${DEST}/vpn"
      vpn_found=1
    fi
  done
  
  if [[ $vpn_found -eq 0 ]]; then
    MISSING_COUNT=$((MISSING_COUNT + 1))
    echo -e "${YELLOW}[✗]${NC} ${BOLD}VPN Configurations${NC}"
    echo -e "    No VPN configs found in common locations"
  fi
  echo ""
fi

# ============================================================================
# 5) Browser Profiles (Firefox, Chrome, Safari, Zen)
# ============================================================================
if [[ -z "${NO_BROWSERS-}" ]]; then
  echo -e "${BOLD}[5/9] Browser Profiles${NC}"
  
  # Firefox
  if [[ -d "${HOME}/Library/Application Support/Firefox/Profiles" ]]; then
    ff_profiles=$(ls -1 "${HOME}/Library/Application Support/Firefox/Profiles" 2>/dev/null | wc -l | tr -d ' ')
    # Check for certificate databases
    cert_dbs=$(find "${HOME}/Library/Application Support/Firefox/Profiles" -name "cert9.db" -o -name "key4.db" 2>/dev/null | wc -l | tr -d ' ')
    check_secret "Firefox Profiles" "${HOME}/Library/Application Support/Firefox/Profiles" "Profiles: ${ff_profiles} (passwords, cookies, extensions, ${cert_dbs} cert DBs)"
    safe_copy "${HOME}/Library/Application Support/Firefox/Profiles" "${DEST}/browsers/firefox"
  else
    check_secret "Firefox Profiles" "${HOME}/Library/Application Support/Firefox/Profiles" "Firefox not found"
  fi
  
  # Zen Browser (Firefox-based)
  if [[ -d "${HOME}/Library/Application Support/zen/Profiles" ]]; then
    zen_profiles=$(ls -1 "${HOME}/Library/Application Support/zen/Profiles" 2>/dev/null | wc -l | tr -d ' ')
    check_secret "Zen Browser Profiles" "${HOME}/Library/Application Support/zen/Profiles" "Profiles: ${zen_profiles} (passwords, cookies, extensions, certificates)"
    safe_copy "${HOME}/Library/Application Support/zen/Profiles" "${DEST}/browsers/zen"
    safe_copy "${HOME}/Library/Application Support/zen/profiles.ini" "${DEST}/browsers/zen" 2>/dev/null || true
  else
    check_secret "Zen Browser Profiles" "${HOME}/Library/Application Support/zen/Profiles" "Zen Browser not found"
  fi
  
  # Chrome
  if [[ -d "${HOME}/Library/Application Support/Google/Chrome" ]]; then
    check_secret "Chrome Profile" "${HOME}/Library/Application Support/Google/Chrome" "Passwords, cookies, extensions, history"
    safe_copy "${HOME}/Library/Application Support/Google/Chrome" "${DEST}/browsers/chrome"
  else
    check_secret "Chrome Profile" "${HOME}/Library/Application Support/Google/Chrome" "Chrome not found"
  fi
  
  # Safari bookmarks
  if [[ -f "${HOME}/Library/Safari/Bookmarks.plist" ]]; then
    check_secret "Safari Bookmarks" "${HOME}/Library/Safari/Bookmarks.plist" "Safari bookmarks and reading list"
    safe_copy "${HOME}/Library/Safari/Bookmarks.plist" "${DEST}/browsers/safari"
    safe_copy "${HOME}/Library/Safari/History.db" "${DEST}/browsers/safari" 2>/dev/null || true
  else
    check_secret "Safari Bookmarks" "${HOME}/Library/Safari/Bookmarks.plist" "Safari not found"
  fi
  echo ""
fi

# ============================================================================
# 6) GPG Keys (Enhanced with actual backup)
# ============================================================================
if [[ -z "${NO_GPG-}" ]]; then
  echo -e "${BOLD}[6/9] GPG Keys${NC}"
  if command -v gpg >/dev/null 2>&1; then
    secret_keys=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "^sec" || echo "0")
    
    
    if [[ $secret_keys -gt 0 ]]; then
      check_secret "GPG Keys" "${HOME}/.gnupg" "Secret keys: ${secret_keys}"
      
      if [[ $DRY_RUN -eq 0 ]]; then
        mkdir -p "${DEST}/gpg"
        
        # Export all private keys
        echo -e "${GREEN}✓${NC} Exporting private keys..."
        gpg --export-secret-keys --armor > "${DEST}/gpg/private_keys_backup.asc" 2>/dev/null || true
        
        # Export all public keys
        echo -e "${GREEN}✓${NC} Exporting public keys..."
        gpg --export --armor > "${DEST}/gpg/public_keys_backup.asc" 2>/dev/null || true
        
        # Export ownertrust
        echo -e "${GREEN}✓${NC} Exporting ownertrust..."
        gpg --export-ownertrust > "${DEST}/gpg/ownertrust.txt" 2>/dev/null || true
        
        # List keys for reference
        gpg --list-secret-keys --keyid-format LONG > "${DEST}/gpg/secret_keys_list.txt" 2>/dev/null || true
        gpg --list-keys --keyid-format LONG > "${DEST}/gpg/public_keys_list.txt" 2>/dev/null || true
        
        # Copy gnupg directory (contains trust db and other settings)
        safe_copy "${HOME}/.gnupg" "${DEST}/gpg/gnupg_backup"
        
        chmod 600 "${DEST}/gpg"/*.asc 2>/dev/null || true
        chmod 600 "${DEST}/gpg"/*.txt 2>/dev/null || true
      fi
    else
      check_secret "GPG Keys" "${HOME}/.gnupg" "No secret keys found"
    fi
  else
    MISSING_COUNT=$((MISSING_COUNT + 1))
    echo -e "${YELLOW}[✗]${NC} ${BOLD}GPG Keys${NC}"
    echo -e "    GPG not installed"
  fi
  echo ""
fi

# ============================================================================
# 7) Certificates and DNIe (Spanish National ID)
# ============================================================================
if [[ -z "${NO_CERTS-}" ]]; then
  echo -e "${BOLD}[7/9] Certificates and DNIe${NC}"
  
  # Check for common certificate locations
  cert_found=0
  
  # User certificates directory
  if [[ -d "${HOME}/Library/Keychains" ]]; then
    check_secret "Keychain Certificates" "${HOME}/Library/Keychains" "User keychains (may contain DNIe certs)"
    safe_copy "${HOME}/Library/Keychains" "${DEST}/certificates/keychains"
    cert_found=1
  fi
  
  # Check for exported certificates
  if [[ -d "${HOME}/Documents/Certificates" ]] || [[ -d "${HOME}/Desktop/Certificates" ]]; then
    local cert_dir="${HOME}/Documents/Certificates"
    [[ -d "${HOME}/Desktop/Certificates" ]] && cert_dir="${HOME}/Desktop/Certificates"
    check_secret "Exported Certificates" "$cert_dir" "Previously exported certificates"
    safe_copy "$cert_dir" "${DEST}/certificates/exported"
    cert_found=1
  fi
  
  # Look for .p12 or .pfx files (common certificate formats)
  p12_files=$(find "${HOME}/Documents" "${HOME}/Desktop" "${HOME}/Downloads" -maxdepth 2 -type f \( -name "*.p12" -o -name "*.pfx" -o -name "*.cer" \) 2>/dev/null | wc -l | tr -d ' ')
  if [[ $p12_files -gt 0 ]]; then
    echo -e "${GREEN}[✓]${NC} ${BOLD}Certificate Files${NC}"
    echo -e "    Found ${p12_files} certificate files (.p12/.pfx/.cer)"
    echo -e "    ${YELLOW}Note: Review and copy manually if needed${NC}"
    cert_found=1
  fi
  
  if [[ $cert_found -eq 0 ]]; then
    MISSING_COUNT=$((MISSING_COUNT + 1))
    echo -e "${YELLOW}[✗]${NC} ${BOLD}Certificates${NC}"
    echo -e "    No certificates found in common locations"
  fi
  
  # Check for DNIe certificates in Keychain
  echo -e "${YELLOW}[!]${NC} ${BOLD}DNIe (Spanish National ID)${NC}"
  if security find-certificate -a 2>/dev/null | grep -i "fnmt\|dnie" >/dev/null 2>&1; then
    echo -e "    ${GREEN}✓ DNIe certificates detected in Keychain${NC}"
    
    if [[ $DRY_RUN -eq 0 ]]; then
      mkdir -p "${DEST}/certificates/dnie"
      
      # Try to list DNIe certificates with their identities
      echo -e "    ${BLUE}Attempting to identify DNIe certificates...${NC}"
      security find-certificate -a -p 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null | grep -i "fnmt\|ceres\|dnie" > "${DEST}/certificates/dnie/detected_certificates.txt" 2>/dev/null || true
      
      # Create export script for user to run
      cat > "${DEST}/certificates/dnie/export_dnie.sh" <<'DNIE_SCRIPT'
#!/bin/bash
# Semi-automated DNIe certificate export script
# This script will help you export DNIe certificates from Keychain

set -e

echo "--- DNIe Certificate Export Tool ---"
echo ""
echo "This script will search for and help export your DNIe certificates."
echo "You will be prompted for your keychain password."
echo ""

# Find FNMT certificates
echo "Searching for FNMT/DNIe certificates..."
CERTS=$(security find-certificate -a -c "FNMT" -c "CERES" 2>/dev/null | grep "labl" | cut -d'"' -f4 || true)

if [ -z "$CERTS" ]; then
    echo "No FNMT/DNIe certificates found in keychain."
    exit 1
fi

echo "Found certificates:"
echo "$CERTS" | nl
echo ""

# Export each certificate
COUNT=1
while IFS= read -r cert_name; do
    if [ -n "$cert_name" ]; then
        echo "Exporting: $cert_name"
        output_file="dnie_cert_${COUNT}.p12"
        
        # Try to export (will prompt for password)
        if security export -k login.keychain -t identities -f pkcs12 -P "" -o "$output_file" 2>/dev/null; then
            echo "✓ Exported to: $output_file"
            echo "  (No password set - you should set one when importing on new machine)"
        else
            echo "✗ Failed to export $cert_name"
            echo "  You may need to export this manually from Keychain Access"
        fi
        
        COUNT=$((COUNT + 1))
    fi
done <<< "$CERTS"

echo ""
echo "Export complete! Files saved in current directory."
echo "Transfer these .p12 files securely to your new machine."
DNIE_SCRIPT
      
      chmod +x "${DEST}/certificates/dnie/export_dnie.sh"
      
      cat > "${DEST}/certificates/dnie/EXPORT_INSTRUCTIONS.txt" <<'DNIE_EOF'
DNIe CERTIFICATE EXPORT INSTRUCTIONS
=====================================

Your DNIe (Spanish National ID) certificates were detected in Keychain.

OPTION 1: SEMI-AUTOMATED EXPORT (RECOMMENDED)
----------------------------------------------
Run the provided export script:

    cd certificates/dnie
    ./export_dnie.sh

This script will:
- Find all FNMT/DNIe certificates
- Attempt to export them as .p12 files
- Prompt for your keychain password when needed

OPTION 2: MANUAL EXPORT
------------------------
If the script doesn't work, export manually:

1. Open "Keychain Access" application
2. In the search box, type: FNMT
3. You should see certificates like:
   - AC Administración Pública
   - AC Componentes Informáticos
   - Your personal DNIe certificate

4. For EACH certificate:
   a. Right-click on the certificate
   b. Select "Export..."
   c. Choose format: "Personal Information Exchange (.p12)"
   d. Save with a descriptive name (e.g., "dnie_personal.p12")
   e. Set a STRONG password (you'll need this on the new machine)
   f. Save to this directory

IMPORTING ON NEW MACHINE
-------------------------
1. Copy all .p12 files to new machine
2. Double-click each .p12 file
3. Enter the password you set during export
4. The certificate will be imported to Keychain

IMPORTANT: Keep the .p12 files and passwords secure!
DNIE_EOF
      chmod 600 "${DEST}/certificates/dnie/EXPORT_INSTRUCTIONS.txt"
      
      echo -e "    ${GREEN}✓${NC} Created export script: ${DEST}/certificates/dnie/export_dnie.sh"
      echo -e "    ${YELLOW}Run the script to semi-automate DNIe export${NC}"
    else
      echo -e "    ${YELLOW}Manual export required (see instructions in staging dir)${NC}"
    fi
  else
    echo -e "    ${YELLOW}No DNIe certificates detected in Keychain${NC}"
    echo -e "    If you have DNIe, export manually from Keychain Access"
  fi
  echo ""
fi

# ============================================================================
# 8) Configuration Files with Secrets
# ============================================================================
if [[ -z "${NO_CONFIGS-}" ]]; then
  echo -e "${BOLD}[8/9] Configuration Files${NC}"
  
  CONFIG_FILES=(
    "${HOME}/.netrc:Network credentials (FTP, HTTP auth)"
    "${HOME}/.npmrc:NPM registry authentication tokens"
    "${HOME}/.docker/config.json:Docker registry credentials"
    "${HOME}/.kube/config:Kubernetes contexts and certificates"
    "${HOME}/.config/gh/hosts.yml:GitHub CLI authentication tokens"
    "${HOME}/.pypirc:Python package index credentials"
    "${HOME}/.gem/credentials:Ruby gem credentials"
    "${HOME}/.cargo/credentials:Rust cargo credentials"
    "${HOME}/.config/gcloud:Google Cloud SDK configuration"
    "${HOME}/.azure:Azure CLI configuration"
    "${HOME}/.terraform.d:Terraform credentials"
  )
  
  for entry in "${CONFIG_FILES[@]}"; do
    IFS=':' read -r path desc <<< "$entry"
    if [[ -e "$path" ]]; then
      check_secret "Config File" "$path" "$desc"
      file_basename=$(basename "$path")
      safe_copy "$path" "${DEST}/configs/${file_basename}"
    fi
  done
  
  # Check for password manager databases (if stored locally)
  if [[ -d "${HOME}/Library/Application Support/1Password" ]]; then
    echo -e "${YELLOW}[!]${NC} ${BOLD}1Password${NC}"
    echo -e "    Found at: ${HOME}/Library/Application Support/1Password"
    echo -e "    ${YELLOW}Note: Usually synced via cloud, verify backup status${NC}"
  fi
  
  if [[ -d "${HOME}/Library/Application Support/LastPass" ]]; then
    echo -e "${YELLOW}[!]${NC} ${BOLD}LastPass${NC}"
    echo -e "    Found at: ${HOME}/Library/Application Support/LastPass"
    echo -e "    ${YELLOW}Note: Usually synced via cloud, verify backup status${NC}"
  fi
  
  echo ""
fi

# ============================================================================
# 9) Additional Important Files
# ============================================================================
echo -e "${BOLD}[9/9] Additional Files${NC}"

# .gitconfig (may contain tokens in [credential] section)
if [[ -f "${HOME}/.gitconfig" ]]; then
  if grep -q "credential" "${HOME}/.gitconfig" 2>/dev/null; then
    check_secret "Git Config" "${HOME}/.gitconfig" "May contain credential helpers or tokens"
    safe_copy "${HOME}/.gitconfig" "${DEST}/configs"
  fi
fi

# Environment files that might have secrets
ENV_FILES=(
  "${HOME}/.env"
  "${HOME}/.envrc"
  "${HOME}/.profile"
  "${HOME}/.bash_profile"
  "${HOME}/.zshenv"
)

for env_file in "${ENV_FILES[@]}"; do
  if [[ -f "$env_file" ]] && grep -qE "(API|TOKEN|KEY|SECRET|PASSWORD)" "$env_file" 2>/dev/null; then
    check_secret "Environment File" "$env_file" "Contains potential secrets (API keys, tokens)"
    safe_copy "$env_file" "${DEST}/configs"
  fi
done

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}${BOLD}=== Summary ===${NC}"
echo -e "${GREEN}Found:${NC} ${FOUND_COUNT} categories"
echo -e "${YELLOW}Missing:${NC} ${MISSING_COUNT} categories"
echo -e "${BLUE}Total estimated size:${NC} $(format_size $TOTAL_SIZE)"

if [[ $DRY_RUN -eq 1 ]]; then
  echo -e "\n${YELLOW}${BOLD}This was a dry run. No files were copied.${NC}"
  echo -e "Run without --dry-run to actually copy the files."
else
  echo -e "\n${GREEN}${BOLD}Staging complete!${NC}"
  echo -e "Review ${DEST} and transfer securely."
  echo -e "${RED}${BOLD}Remember to delete staging directory after transfer!${NC}"
fi

# ============================================================================
# Create comprehensive README
# ============================================================================
if [[ $DRY_RUN -eq 0 ]]; then
  cat > "${DEST}/README.txt" <<'EOF'
================================================================================
SECRETS STAGING DIRECTORY - TRANSFER GUIDE
================================================================================

This directory contains sensitive files staged by scripts/stage_secrets.sh.
⚠️  DO NOT COMMIT .secrets_staging to git.
⚠️  DELETE this directory after successful transfer.

================================================================================
SECURE TRANSFER INSTRUCTIONS
================================================================================

1. CREATE ENCRYPTED DISK IMAGE:
   hdiutil create -encryption -size 500m -fs APFS -volname SecureTransfer transfer.dmg
   (You'll be prompted to set a password - use a strong one!)

2. MOUNT THE IMAGE:
   hdiutil attach transfer.dmg
   (Enter the password you just set)

3. COPY STAGED FILES:
   cp -a .secrets_staging/* /Volumes/SecureTransfer/

4. UNMOUNT:
   hdiutil detach /Volumes/SecureTransfer

5. TRANSFER SECURELY:
   - USB drive (encrypted)
   - scp transfer.dmg user@newmachine:/path/
   - AirDrop (if both machines are yours)

6. ON NEW MACHINE:
   hdiutil attach transfer.dmg
   (Follow restore instructions below)

7. CLEANUP:
   - Securely delete DMG: rm -P transfer.dmg
   - Delete staging: rm -rf .secrets_staging

================================================================================
RESTORE INSTRUCTIONS BY CATEGORY
================================================================================

SSH KEYS (ssh/)
---------------
1. Copy to new machine:
   cp -a ssh/.ssh ~/
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_* ~/.ssh/config
   chmod 644 ~/.ssh/*.pub

2. Test SSH connection:
   ssh -T git@github.com

AWS CREDENTIALS (aws/)
----------------------
1. Copy to new machine:
   cp -a aws/.aws ~/
   chmod 700 ~/.aws
   chmod 600 ~/.aws/credentials ~/.aws/config

2. Verify:
   aws sts get-caller-identity

BROWSER PROFILES (browsers/)
----------------------------
Firefox:
1. Close Firefox
2. Find profile directory:
   ~/Library/Application Support/Firefox/Profiles/
3. Copy profile folder or merge specific files:
   - key4.db (passwords)
   - logins.json (passwords)
   - cookies.sqlite
   - places.sqlite (bookmarks/history)
   - extensions/

Chrome:
1. Close Chrome
2. Copy to:
   ~/Library/Application Support/Google/Chrome/
3. Or use Chrome Sync for easier transfer

Safari:
1. Copy Bookmarks.plist to:
   ~/Library/Safari/
2. Restart Safari

GPG KEYS (gpg/)
---------------
1. Import private keys:
   gpg --import gpg/private_keys_backup.asc

2. Import public keys:
   gpg --import gpg/public_keys_backup.asc

3. Import trust database:
   gpg --import-ownertrust gpg/ownertrust.txt

4. Verify:
   gpg --list-secret-keys

5. Optional - restore full gnupg directory:
   cp -a gpg/gnupg_backup/.gnupg ~/
   chmod 700 ~/.gnupg
   chmod 600 ~/.gnupg/*

CERTIFICATES (certificates/)
----------------------------
Keychain:
1. Open Keychain Access on new machine
2. File → Import Items
3. Select .p12 files from certificates/
4. Enter password when prompted

DNIe (Spanish National ID):
1. Install DNIe drivers on new machine
2. Import certificate from certificates/dnie/
3. Or re-export from old machine:
   - Open Keychain Access
   - Find DNIe certificate
   - Right-click → Export
   - Save as .p12 with password

CONFIGURATION FILES (configs/)
------------------------------
For each config file, copy to home directory:

.netrc:
  cp configs/.netrc ~/
  chmod 600 ~/.netrc

.npmrc:
  cp configs/.npmrc ~/
  chmod 600 ~/.npmrc

.docker/config.json:
  mkdir -p ~/.docker
  cp configs/config.json ~/.docker/
  chmod 600 ~/.docker/config.json

.kube/config:
  mkdir -p ~/.kube
  cp configs/config ~/.kube/
  chmod 600 ~/.kube/config

GitHub CLI:
  mkdir -p ~/.config/gh
  cp configs/hosts.yml ~/.config/gh/
  chmod 600 ~/.config/gh/hosts.yml

VPN CONFIGURATIONS (vpn/)
-------------------------
Depends on VPN client:

Tunnelblick:
1. Copy to: ~/Library/Application Support/Tunnelblick/
2. Restart Tunnelblick

OpenVPN:
1. Copy configs to appropriate location
2. Import in OpenVPN client

WireGuard:
1. Import .conf files in WireGuard app

INTELLIJ/JETBRAINS (intellij/)
-------------------------------
1. Install IDE on new machine
2. Close IDE
3. Copy settings to:
   ~/Library/Application Support/JetBrains/
4. Restart IDE
5. Or use IDE's built-in Settings Sync feature

================================================================================
VERIFICATION CHECKLIST
================================================================================

After restore, verify:
□ SSH keys work (test git clone)
□ AWS credentials work (aws sts get-caller-identity)
□ GPG keys imported (gpg --list-secret-keys)
□ Browser profiles restored (check saved passwords)
□ VPN connections work
□ Docker registry login works
□ Kubernetes contexts accessible
□ GitHub CLI authenticated (gh auth status)
□ IDE settings restored

================================================================================
SECURITY NOTES
================================================================================

1. File permissions are set to:
   - Directories: 700 (rwx------)
   - Files: 600 (rw-------)

2. After successful transfer and verification:
   - Securely delete the DMG: rm -P transfer.dmg
   - Delete staging directory: rm -rf .secrets_staging
   - Clear bash history if it contains sensitive commands

3. Consider rotating credentials after transfer:
   - Generate new SSH keys
   - Rotate API tokens
   - Update passwords

4. Some items may require manual intervention:
   - Keychain certificates
   - Password manager databases
   - Application-specific licenses

================================================================================
TROUBLESHOOTING
================================================================================

SSH keys not working:
- Check permissions: chmod 600 ~/.ssh/id_*
- Check SSH agent: ssh-add -l
- Add key: ssh-add ~/.ssh/id_rsa

GPG keys not working:
- Check trust: gpg --edit-key <KEY_ID> trust
- Restart gpg-agent: gpgconf --kill gpg-agent

AWS credentials not working:
- Check profile: aws configure list
- Verify region is set

Browser profiles not loading:
- Check profile path in browser settings
- May need to create new profile and copy data

================================================================================
SUPPORT
================================================================================

For issues with this script or transfer process:
1. Check file permissions
2. Verify paths match your system
3. Review application-specific documentation
4. Consider using application's built-in export/import features

Generated by: scripts/stage_secrets.sh
Permissions: directories = 700, files = 600
EOF

  chmod 600 "${DEST}/README.txt"
  echo -e "\n${GREEN}✓${NC} Created comprehensive README at ${DEST}/README.txt"
fi

echo ""