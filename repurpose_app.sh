#!/bin/bash
#
# Repurpose App Script
# Run this script inside a COPIED project root (the folder that contains
# "Calories Deficit Tracker" and "Calories Deficit Tracker.xcodeproj").
#
# Usage:
#   ./repurpose_app.sh "New App Name" com.example.newapp [monthlyProductId] [yearlyProductId]
#
# Example:
#   ./repurpose_app.sh "My Fitness App" com.fclarke.myFitnessApp myAppMonthly myAppYearly
#
# If monthly/yearly product IDs are omitted, existing IDs (caloriesMonthly, caloriesYearly) are kept.
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OLD_DISPLAY_NAME="Calories Deficit Tracker"
OLD_SANITIZED="Calories_Deficit_Tracker"
OLD_BUNDLE_ID="com.fclarke.caloriesDeficitTracker"
OLD_MONTHLY_ID="caloriesMonthly"
OLD_YEARLY_ID="caloriesYearly"

if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 \"New App Name\" com.example.bundleid [monthlyProductId] [yearlyProductId]${NC}"
    echo "Example: $0 \"My New App\" com.fclarke.myNewApp myAppMonthly myAppYearly"
    exit 1
fi

NEW_DISPLAY_NAME="$1"
NEW_BUNDLE_ID="$2"
NEW_MONTHLY_ID="${3:-$OLD_MONTHLY_ID}"
NEW_YEARLY_ID="${4:-$OLD_YEARLY_ID}"

# Sanitized name: spaces -> underscores, for file names and struct names
NEW_SANITIZED=$(echo "$NEW_DISPLAY_NAME" | sed 's/ /_/g' | sed 's/[^a-zA-Z0-9_]//g')
if [ -z "$NEW_SANITIZED" ]; then
    NEW_SANITIZED="App"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check we're in the right place
if [ ! -d "$OLD_DISPLAY_NAME" ] || [ ! -d "${OLD_DISPLAY_NAME}.xcodeproj" ]; then
    echo -e "${RED}Error: Run this script from the copied project root (containing \"$OLD_DISPLAY_NAME\" and \"$OLD_DISPLAY_NAME.xcodeproj\").${NC}"
    exit 1
fi

echo -e "${BLUE}Repurposing app:${NC}"
echo "  Display name: $NEW_DISPLAY_NAME"
echo "  Sanitized:    $NEW_SANITIZED"
echo "  Bundle ID:    $NEW_BUNDLE_ID"
echo "  Monthly ID:   $NEW_MONTHLY_ID"
echo "  Yearly ID:    $NEW_YEARLY_ID"
echo ""

# sed in-place: macOS vs Linux
sed_i() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Escape string for sed replacement ( & \ and newlines)
escape_sed_replace() {
    echo "$1" | sed 's/[&\\]/\\&/g' | sed ':a;N;$!ba;s/\n/\\n/g'
}

# Escape string for sed pattern (regex metacharacters; backslash first)
escape_sed_pattern() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/[.*^$()+?{|[\]/\\&/g'
}

replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    if [ -f "$file" ]; then
        local pat
        local repl
        pat=$(escape_sed_pattern "$search")
        repl=$(escape_sed_replace "$replace")
        sed_i "s|$pat|$repl|g" "$file"
    fi
}

echo -e "${BLUE}Step 1: Updating project.pbxproj...${NC}"
PBXPROJ="${OLD_DISPLAY_NAME}.xcodeproj/project.pbxproj"
replace_in_file "$PBXPROJ" "$OLD_DISPLAY_NAME" "$NEW_DISPLAY_NAME"
replace_in_file "$PBXPROJ" "$OLD_SANITIZED" "$NEW_SANITIZED"
replace_in_file "$PBXPROJ" "$OLD_BUNDLE_ID" "$NEW_BUNDLE_ID"
echo "  Done."

echo -e "${BLUE}Step 2: Updating scheme...${NC}"
SCHEME_DIR="${OLD_DISPLAY_NAME}.xcodeproj/xcshareddata/xcschemes"
SCHEME_FILE="${SCHEME_DIR}/${OLD_DISPLAY_NAME}.xcscheme"
if [ -f "$SCHEME_FILE" ]; then
    replace_in_file "$SCHEME_FILE" "$OLD_DISPLAY_NAME" "$NEW_DISPLAY_NAME"
    echo "  Done."
else
    echo -e "  ${YELLOW}Scheme file not found, skipping.${NC}"
fi

echo -e "${BLUE}Step 3: Updating Swift sources (headers, struct name, product IDs)...${NC}"
APP_DIR="$OLD_DISPLAY_NAME"
for f in "$APP_DIR"/*.swift; do
    [ -f "$f" ] || continue
    replace_in_file "$f" "//  $OLD_DISPLAY_NAME" "//  $NEW_DISPLAY_NAME"
    replace_in_file "$f" "//  ${OLD_SANITIZED}App" "//  ${NEW_SANITIZED}App"
    replace_in_file "$f" "struct ${OLD_SANITIZED}App" "struct ${NEW_SANITIZED}App"
    replace_in_file "$f" "$OLD_DISPLAY_NAME does not" "$NEW_DISPLAY_NAME does not"
    replace_in_file "$f" "$OLD_MONTHLY_ID" "$NEW_MONTHLY_ID"
    replace_in_file "$f" "$OLD_YEARLY_ID" "$NEW_YEARLY_ID"
done
echo "  Done."

echo -e "${BLUE}Step 4: Renaming inner app folder...${NC}"
mv "$OLD_DISPLAY_NAME" "$NEW_DISPLAY_NAME"
APP_DIR="$NEW_DISPLAY_NAME"
echo "  Renamed to: $APP_DIR"

echo -e "${BLUE}Step 5: Renaming .xcodeproj...${NC}"
mv "${OLD_DISPLAY_NAME}.xcodeproj" "${NEW_DISPLAY_NAME}.xcodeproj"
echo "  Renamed to: ${NEW_DISPLAY_NAME}.xcodeproj"

echo -e "${BLUE}Step 6: Renaming scheme file...${NC}"
SCHEME_DIR="${NEW_DISPLAY_NAME}.xcodeproj/xcshareddata/xcschemes"
if [ -d "$SCHEME_DIR" ]; then
    if [ -f "${SCHEME_DIR}/${OLD_DISPLAY_NAME}.xcscheme" ]; then
        mv "${SCHEME_DIR}/${OLD_DISPLAY_NAME}.xcscheme" "${SCHEME_DIR}/${NEW_DISPLAY_NAME}.xcscheme"
        echo "  Renamed to: ${NEW_DISPLAY_NAME}.xcscheme"
    fi
fi

echo -e "${BLUE}Step 7: Renaming entitlements and main app Swift file...${NC}"
if [ -f "${APP_DIR}/${OLD_SANITIZED}.entitlements" ]; then
    mv "${APP_DIR}/${OLD_SANITIZED}.entitlements" "${APP_DIR}/${NEW_SANITIZED}.entitlements"
    echo "  Entitlements: ${NEW_SANITIZED}.entitlements"
fi
if [ -f "${APP_DIR}/${OLD_SANITIZED}App.swift" ]; then
    mv "${APP_DIR}/${OLD_SANITIZED}App.swift" "${APP_DIR}/${NEW_SANITIZED}App.swift"
    echo "  App file: ${NEW_SANITIZED}App.swift"
fi

echo ""
echo -e "${GREEN}Repurpose complete.${NC}"
echo "  - Open ${NEW_DISPLAY_NAME}.xcodeproj in Xcode and build."
echo "  - Replace AppIcon.appiconset contents in ${APP_DIR}/Assets.xcassets/ with your new icon."
echo "  - In App Store Connect, create an app with bundle ID $NEW_BUNDLE_ID and subscription products $NEW_MONTHLY_ID and $NEW_YEARLY_ID if needed."
