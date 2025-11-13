#!/usr/bin/env bash
# scripts/stage_secrets.sh
# Copy sensitive files into a local, git-ignored staging directory for secure transfer.
#
# Usage:
#   ./scripts/stage_secrets.sh [--dest ./ ./.secrets_staging] [--include intellij,vpn,aws,ssh]
#
# Default behavior: copies SSH private keys, AWS creds (if present), IntelliJ settings (if present),
# and common VPN configs (e.g., ~/Library/Application Support/OpenVPN, /etc/openvpn) into ./.secrets_staging
# The script will set restrictive permissions (0700 for dir, 0600 for files) and will NOT git add the files.
#
set -euo pipefail

DEST="${PWD}/.secrets_staging"
INCLUDE_ALL=1

usage() {
  cat <<EOF
stage_secrets.sh - gather private files into a local staging dir (gitignored)

Usage:
  $0 [--dest /abs/path] [--no-intellij] [--no-vpn] [--no-aws] [--no-ssh] [-h]

By default all categories are included. The staging dir will be created if necessary and will
have permission 700. Files inside will be set to 600. Do NOT commit the staging directory.

Recommended transfer:
  1) Create an encrypted disk image (hdiutil create -encryption -size 100m -fs APFS -volname transfer transfer.dmg)
  2) Mount it and copy contents of .secrets_staging into it
  3) Safely transfer the dmg to the target machine (scp, USB, etc.)
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) DEST="$2"; shift 2;;
    --no-intellij) NO_INTELLIJ=1; shift;;
    --no-vpn) NO_VPN=1; shift;;
    --no-aws) NO_AWS=1; shift;;
    --no-ssh) NO_SSH=1; shift;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

echo "Creating staging dir at ${DEST}"
mkdir -p "${DEST}"
chmod 700 "${DEST}"

# Helper to copy and set permissions
function safe_copy() {
  src="$1"
  dst_dir="$2"
  if [ -e "${src}" ]; then
    mkdir -p "${dst_dir}"
    cp -a "${src}" "${dst_dir}/" 2>/dev/null || true
    # Set restrictive perms
    find "${dst_dir}" -type d -exec chmod 700 {} \; || true
    find "${dst_dir}" -type f -exec chmod 600 {} \; || true
    echo "Copied ${src} -> ${dst_dir}"
  fi
}

# 1) SSH
if [ -z "${NO_SSH-}" ]; then
  echo "Staging SSH keys..."
  if [ -d "${HOME}/.ssh" ]; then
    safe_copy "${HOME}/.ssh" "${DEST}/ssh"
    # remove public keys if you want only private? keep both
  else
    echo "No ~/.ssh directory found"
  fi
fi

# 2) AWS
if [ -z "${NO_AWS-}" ]; then
  echo "Staging AWS credentials..."
  if [ -d "${HOME}/.aws" ]; then
    safe_copy "${HOME}/.aws" "${DEST}/aws"
  fi
fi

# 3) IntelliJ / JetBrains settings
if [ -z "${NO_INTELLIJ-}" ]; then
  echo "Staging IntelliJ/JetBrains settings (if present)..."
  JB_KNOWN=(
    "${HOME}/Library/Application Support/JetBrains"
    "${HOME}/Library/Preferences/JetBrains"
    "${HOME}/Library/Application Support/JetBrains/IntelliJIdea"
    "${HOME}/Library/Preferences/IntelliJIdea"
    "${HOME}/.IdeaIC"
  )
  for d in "${JB_KNOWN[@]}"; do
    if compgen -G "${d}*" >/dev/null; then
      safe_copy "${d}" "${DEST}/intellij"
    fi
  done
fi

# 4) VPN configs - common locations
if [ -z "${NO_VPN-}" ]; then
  echo "Staging VPN configs (OpenVPN, WireGuard, Tunnelblick, Viscosity)..."
  safe_copy "/etc/openvpn" "${DEST}/vpn" || true
  safe_copy "${HOME}/Library/Application Support/Tunnelblick" "${DEST}/vpn" || true
  safe_copy "${HOME}/Library/Application Support/Viscosity" "${DEST}/vpn" || true
  safe_copy "${HOME}/Library/Application Support/WireGuard" "${DEST}/vpn" || true
  # Tunnelblick also stores profiles under ~/Library/Application Support/Tunnelblick/Configurations
fi

# 5) Additional: GPG and SSH agent keys (private)
echo "Staging GPG keys metadata..."
if command -v gpg >/dev/null 2>&1; then
  gpg --list-secret-keys --keyid-format LONG > "${DEST}/gpg_secret_keys_list.txt" 2>/dev/null || true
  # copy private key export only if requested manually (not automatic)
fi

# 6) Create README inside staging dir
cat > "${DEST}/README.txt" <<'EOF'
This directory contains sensitive files staged by scripts/stage_secrets.sh.
DO NOT COMMIT .secrets_staging to git.

Recommended secure transfer:
  1) Create encrypted disk image:
     hdiutil create -encryption -size 200m -fs APFS -volname transfer transfer.dmg
  2) Mount it:
     hdiutil attach transfer.dmg
  3) Copy staged files into the mounted volume:
     cp -a .secrets_staging/* /Volumes/transfer/
  4) Unmount and transfer:
     hdiutil detach /Volumes/transfer
     scp transfer.dmg user@newmachine:/path/
  5) After confirming on target machine securely delete the DMG and remove staging files.

Permissions: directories = 700, files = 600
EOF

echo "Staging complete. Review ${DEST} and transfer securely. Remember to delete it after transfer."


# keep firefox gpg keys, dnie..