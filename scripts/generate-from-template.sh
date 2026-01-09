#!/bin/bash

# generate-from-template.sh
# Generates a complete module structure from the template

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CLAP Orchestrator - Template Generator      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if module name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide a module name${NC}"
    echo "Usage: ./scripts/generate-from-template.sh <module-name>"
    exit 1
fi

MODULE_NAME=$1
MODULE_PATH="modules/${MODULE_NAME}-module"

# Check if module exists
if [ -d "$MODULE_PATH" ]; then
    echo -e "${YELLOW}Warning: Module '${MODULE_NAME}' already exists${NC}"
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        echo "Cancelled."
        exit 0
    fi
    rm -rf "$MODULE_PATH"
fi

echo -e "${BLUE}Generating module structure from template...${NC}"
echo ""

# Create base structure
mkdir -p "$MODULE_PATH/.copilot-instructions"

# Copy all template files
cp .template/module-spec.md "$MODULE_PATH/"
cp .template/.copilot-instructions/*.md "$MODULE_PATH/.copilot-instructions/"
cp .template/i18n-keys.md "$MODULE_PATH/"
cp .template/status.json "$MODULE_PATH/"

# Update timestamps
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
sed -i "s/\[ISO 8601 Timestamp\]/${CREATED_AT}/g" "$MODULE_PATH/status.json"

# Update module name in files
find "$MODULE_PATH" -type f -exec sed -i "s/\[Module Name\]/${MODULE_NAME}/g" {} +
find "$MODULE_PATH" -type f -exec sed -i "s/\[module-name\]/${MODULE_NAME}/g" {} +

echo -e "${GREEN}✓ Module structure generated${NC}"
echo ""
echo -e "${YELLOW}Generated files:${NC}"
echo "  - module-spec.md"
echo "  - i18n-keys.md"
echo "  - status.json"
echo "  - .copilot-instructions/ (6 files)"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Customize the module specification"
echo "2. Update copilot instructions if needed"
echo "3. Run validation: ./scripts/validate-spec.sh ${MODULE_NAME}"
echo ""
