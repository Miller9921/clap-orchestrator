#!/bin/bash

# create-module.sh
# Main script to create a new module across CLAP multi-repo architecture

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CLAP Orchestrator - Module Creator          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check if module name is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Please provide a module name:${NC}"
    read -p "Module name (e.g., user-authentication): " MODULE_NAME
else
    MODULE_NAME=$1
fi

# Sanitize module name
MODULE_NAME=$(echo "$MODULE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
MODULE_PATH="modules/${MODULE_NAME}-module"

echo -e "${GREEN}Creating module: ${MODULE_NAME}${NC}"
echo ""

# Check if module already exists
if [ -d "$MODULE_PATH" ]; then
    echo -e "${RED}Error: Module '${MODULE_NAME}' already exists at ${MODULE_PATH}${NC}"
    exit 1
fi

# Create module directory structure
echo -e "${BLUE}Creating module directory structure...${NC}"
mkdir -p "$MODULE_PATH"
mkdir -p "$MODULE_PATH/.copilot-instructions"

# Copy template files
echo -e "${BLUE}Copying template files...${NC}"
cp .template/module-spec.md "$MODULE_PATH/"
cp .template/.copilot-instructions/*.md "$MODULE_PATH/.copilot-instructions/"
cp .template/i18n-keys.md "$MODULE_PATH/"
cp .template/status.json "$MODULE_PATH/"

# Update status.json with module info
echo -e "${BLUE}Updating module status file...${NC}"
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
sed -i "s/\[Module Name\]/${MODULE_NAME}/g" "$MODULE_PATH/status.json"
sed -i "s/\[ISO 8601 Timestamp\]/${CREATED_AT}/g" "$MODULE_PATH/status.json"
sed -i "s/\[module-name\]/${MODULE_NAME}/g" "$MODULE_PATH/status.json"

echo -e "${GREEN}✓ Module structure created${NC}"
echo ""

# Interactive prompts for module details
echo -e "${YELLOW}Please provide some details about your module:${NC}"
echo ""

read -p "Module purpose (brief description): " MODULE_PURPOSE
read -p "Primary entity name (e.g., User, Payment): " ENTITY_NAME

echo ""
echo -e "${BLUE}Module created successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit the module specification:"
echo -e "   ${GREEN}${MODULE_PATH}/module-spec.md${NC}"
echo ""
echo "2. Fill in the copilot instructions:"
echo -e "   ${GREEN}${MODULE_PATH}/.copilot-instructions/${NC}"
echo ""
echo "3. Add i18n keys:"
echo -e "   ${GREEN}${MODULE_PATH}/i18n-keys.md${NC}"
echo ""
echo "4. Validate your module:"
echo -e "   ${GREEN}./scripts/validate-spec.sh ${MODULE_NAME}${NC}"
echo ""
echo "5. Trigger the GitHub workflow to create PRs:"
echo -e "   ${GREEN}gh workflow run create-module-prs.yml -f module_name=${MODULE_NAME} -f module_path=${MODULE_PATH}${NC}"
echo ""
echo -e "${BLUE}Track progress at:${NC}"
echo -e "   ${GREEN}https://github.com/Miller9921/clap-orchestrator/actions${NC}"
echo ""
