#!/usr/bin/env bash

# Validation script for mise → devbox migration
# This script performs read-only checks to verify the migration setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_check() {
    local status=$1
    local message=$2
    local detail=$3
    
    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}✅${NC} $message"
        [ -n "$detail" ] && echo -e "   ${detail}"
        ((PASSED++))
    elif [ "$status" = "fail" ]; then
        echo -e "${RED}❌${NC} $message"
        [ -n "$detail" ] && echo -e "   ${RED}${detail}${NC}"
        ((FAILED++))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠️${NC}  $message"
        [ -n "$detail" ] && echo -e "   ${YELLOW}${detail}${NC}"
        ((WARNINGS++))
    fi
}

print_summary() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}SUMMARY${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Passed:${NC}   $PASSED"
    echo -e "${RED}Failed:${NC}   $FAILED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Start validation
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Devbox Migration Validation Script                       ║${NC}"
echo -e "${BLUE}║  Checking mise → devbox migration setup                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Check 1: Verify devbox is installed
print_header "1. Devbox Installation Check"
if command -v devbox &> /dev/null; then
    DEVBOX_VERSION=$(devbox version 2>&1 | head -n 1)
    print_check "pass" "Devbox is installed" "$DEVBOX_VERSION"
else
    print_check "fail" "Devbox is not installed" "Run: curl -fsSL https://get.jetify.com/devbox | bash"
fi

# Check 2: Verify devbox.json exists in correct location
print_header "2. Global Configuration Check"
DEVBOX_CONFIG="$HOME/.local/share/devbox/global/default/devbox.json"
if [ -f "$DEVBOX_CONFIG" ]; then
    print_check "pass" "devbox.json exists in correct location" "Location: $DEVBOX_CONFIG"
    
    # Verify using devbox global path command
    if command -v devbox &> /dev/null; then
        DEVBOX_PATH=$(devbox global path 2>/dev/null || echo "")
        if [ -n "$DEVBOX_PATH" ]; then
            print_check "pass" "devbox global path verified" "Path: $DEVBOX_PATH"
        fi
    fi
    
    # Validate JSON syntax
    if command -v jq &> /dev/null; then
        if jq empty "$DEVBOX_CONFIG" 2>/dev/null; then
            print_check "pass" "devbox.json has valid JSON syntax"
        else
            print_check "fail" "devbox.json has invalid JSON syntax"
        fi
    else
        print_check "warn" "jq not available, skipping JSON validation" "Install jq to validate JSON syntax"
    fi
else
    print_check "fail" "devbox.json not found in correct location" "Expected: $DEVBOX_CONFIG - Run bootstrap.sh to copy the configuration"
    
    # Check for old location
    if [ -f "$HOME/.devbox-global.json" ]; then
        print_check "warn" "Old .devbox-global.json found" "Remove $HOME/.devbox-global.json after migration"
    fi
fi

# Check 3: List devbox global packages
print_header "3. Global Packages Check"
if command -v devbox &> /dev/null && [ -f "$DEVBOX_CONFIG" ]; then
    PACKAGE_COUNT=$(devbox global list 2>/dev/null | grep -c "^" || echo "0")
    if [ "$PACKAGE_COUNT" -gt 0 ]; then
        print_check "pass" "Devbox global packages configured" "$PACKAGE_COUNT packages found"
        echo -e "\n   ${BLUE}Sample packages:${NC}"
        devbox global list 2>/dev/null | head -n 5 | sed 's/^/   /'
        if [ "$PACKAGE_COUNT" -gt 5 ]; then
            echo -e "   ... and $((PACKAGE_COUNT - 5)) more"
        fi
    else
        print_check "warn" "No global packages found" "Run: devbox global pull"
    fi
else
    print_check "fail" "Cannot list global packages" "Devbox not installed or config missing"
fi

# Check 4: Verify critical tools are available
print_header "4. Critical Tools Availability"
CRITICAL_TOOLS=("git" "node" "python3" "terraform" "kubectl")

for tool in "${CRITICAL_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        VERSION=$($tool --version 2>&1 | head -n 1)
        print_check "pass" "$tool is available" "$VERSION"
    else
        print_check "warn" "$tool is not available" "Will be available after: devbox global pull && eval \"\$(devbox global shellenv)\""
    fi
done

# Check 5: Verify mise is not installed
print_header "5. Mise Removal Check"
if command -v mise &> /dev/null; then
    MISE_VERSION=$(mise --version 2>&1)
    print_check "warn" "mise is still installed" "Version: $MISE_VERSION - Consider removing it"
    
    # Check if mise is in PATH
    MISE_PATH=$(which mise 2>/dev/null || echo "")
    if [ -n "$MISE_PATH" ]; then
        echo -e "   ${YELLOW}Location: $MISE_PATH${NC}"
    fi
else
    print_check "pass" "mise is not installed (as expected)"
fi

# Check 6: Verify .mise.toml is removed
if [ -f "$HOME/.mise.toml" ] || [ -f "$(pwd)/.mise.toml" ]; then
    print_check "warn" ".mise.toml file still exists" "Consider removing old mise configuration files"
else
    print_check "pass" ".mise.toml has been removed"
fi

# Check 7: Verify shell configuration
print_header "6. Shell Configuration Check"
if [ -f "$HOME/.zshrc" ]; then
    if grep -q "devbox global shellenv" "$HOME/.zshrc"; then
        print_check "pass" ".zshrc contains devbox shellenv initialization"
    else
        print_check "fail" ".zshrc missing devbox shellenv initialization" "Add: eval \"\$(devbox global shellenv)\""
    fi
    
    if grep -q "mise activate" "$HOME/.zshrc"; then
        print_check "warn" ".zshrc still contains mise activation" "Remove mise-related lines from .zshrc"
    else
        print_check "pass" ".zshrc does not contain mise activation"
    fi
else
    print_check "warn" ".zshrc not found in home directory"
fi

# Check 8: Verify bootstrap.sh and brew.sh
print_header "7. Installation Scripts Check"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$SCRIPT_DIR/bootstrap.sh" ]; then
    if grep -q "devbox.json" "$SCRIPT_DIR/bootstrap.sh"; then
        print_check "pass" "bootstrap.sh includes devbox configuration"
        
        # Check if it uses the correct path
        if grep -q ".local/share/devbox/global/default" "$SCRIPT_DIR/bootstrap.sh"; then
            print_check "pass" "bootstrap.sh uses correct devbox path"
        else
            print_check "warn" "bootstrap.sh may not use correct devbox path"
        fi
    else
        print_check "warn" "bootstrap.sh may not include devbox configuration"
    fi
else
    print_check "warn" "bootstrap.sh not found"
fi

if [ -f "$SCRIPT_DIR/brew.sh" ]; then
    if grep -q "devbox" "$SCRIPT_DIR/brew.sh"; then
        print_check "pass" "brew.sh includes devbox installation"
    else
        print_check "warn" "brew.sh may not include devbox installation"
    fi
else
    print_check "warn" "brew.sh not found"
fi

# Print summary
print_summary

# Exit with appropriate status code
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Validation failed with $FAILED error(s)${NC}"
    echo -e "${YELLOW}💡 This is expected if you haven't run the migration yet${NC}\n"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Validation completed with $WARNINGS warning(s)${NC}"
    echo -e "${YELLOW}💡 Some warnings are expected before running the migration${NC}\n"
    exit 0
else
    echo -e "${GREEN}✅ All checks passed!${NC}\n"
    exit 0
fi