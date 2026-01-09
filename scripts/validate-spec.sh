#!/bin/bash

# validate-spec.sh
# Validates a module specification before creating PRs

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CLAP Orchestrator - Module Validator        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if module name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide a module name${NC}"
    echo "Usage: ./scripts/validate-spec.sh <module-name>"
    exit 1
fi

MODULE_NAME=$1
MODULE_PATH="modules/${MODULE_NAME}-module"

# Check if module exists
if [ ! -d "$MODULE_PATH" ]; then
    echo -e "${RED}Error: Module '${MODULE_NAME}' not found at ${MODULE_PATH}${NC}"
    exit 1
fi

echo -e "${BLUE}Validating module: ${MODULE_NAME}${NC}"
echo ""

VALIDATION_FAILED=0

# Check for required files
echo -e "${YELLOW}Checking required files...${NC}"

REQUIRED_FILES=(
    "module-spec.md"
    "i18n-keys.md"
    "status.json"
    ".copilot-instructions/01-domain.md"
    ".copilot-instructions/02-infrastructure.md"
    ".copilot-instructions/03-ui.md"
    ".copilot-instructions/04-frontend-admin.md"
    ".copilot-instructions/05-frontend-user.md"
    ".copilot-instructions/06-kiwi-di.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$MODULE_PATH/$file" ]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file (missing)${NC}"
        VALIDATION_FAILED=1
    fi
done

echo ""

# Validate module-spec.md content
echo -e "${YELLOW}Validating module-spec.md content...${NC}"

REQUIRED_SECTIONS=(
    "Module Overview"
    "Domain Layer"
    "Infrastructure Layer"
    "UI Layer"
    "Frontend Admin"
    "Frontend User"
    "i18n Keys"
    "Kiwi DI Setup"
)

SPEC_FILE="$MODULE_PATH/module-spec.md"

for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -qi "$section" "$SPEC_FILE"; then
        echo -e "${GREEN}✓ $section${NC}"
    else
        echo -e "${YELLOW}⚠ $section (not found, may need to be added)${NC}"
    fi
done

echo ""

# Validate status.json
echo -e "${YELLOW}Validating status.json...${NC}"

if [ -f "$MODULE_PATH/status.json" ]; then
    # Check if it's valid JSON
    if python3 -m json.tool "$MODULE_PATH/status.json" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Valid JSON format${NC}"
    else
        echo -e "${RED}✗ Invalid JSON format${NC}"
        VALIDATION_FAILED=1
    fi
else
    echo -e "${RED}✗ status.json not found${NC}"
    VALIDATION_FAILED=1
fi

echo ""

# Check for placeholder text
echo -e "${YELLOW}Checking for placeholder text...${NC}"

if grep -r "\[Module Name\]" "$MODULE_PATH" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Found [Module Name] placeholders - please replace${NC}"
fi

if grep -r "\[Entity\]" "$MODULE_PATH" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Found [Entity] placeholders - please replace${NC}"
fi

echo ""

# Final result
if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Validation PASSED ✓                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Your module is ready to be submitted!${NC}"
    echo ""
    echo "To create PRs across all repositories, run:"
    echo -e "${GREEN}gh workflow run create-module-prs.yml -f module_name=${MODULE_NAME} -f module_path=${MODULE_PATH}${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   Validation FAILED ✗                          ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Please fix the issues above and run validation again.${NC}"
    echo ""
    exit 1
fi
