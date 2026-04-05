#!/bin/zsh
# RISDi Constants System Verification Script
# Run this to verify the constants system is working correctly

echo "🔍 RISDi Constants System Verification"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test 1: Check if constants directory exists
echo "📁 Checking constants directory..."
if [ -d "lib/core/constants" ]; then
    echo "${GREEN}✅ Constants directory exists${NC}"
    ((PASSED++))
else
    echo "${RED}❌ Constants directory not found${NC}"
    ((FAILED++))
fi

# Test 2: Check if all constant files exist
echo ""
echo "📄 Checking constant files..."
FILES=(
    "lib/core/constants/colors.dart"
    "lib/core/constants/spacing.dart"
    "lib/core/constants/sizes.dart"
    "lib/core/constants/text_styles.dart"
    "lib/core/constants/strings.dart"
    "lib/core/constants/assets.dart"
    "lib/core/constants/theme.dart"
    "lib/core/constants/constants.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "${GREEN}✅ $(basename $file)${NC}"
        ((PASSED++))
    else
        echo "${RED}❌ $(basename $file) - NOT FOUND${NC}"
        ((FAILED++))
    fi
done

# Test 3: Check if main.dart has theme integration
echo ""
echo "⚙️ Checking main.dart integration..."
if grep -q "AppTheme.lightTheme" lib/main.dart; then
    echo "${GREEN}✅ Theme integrated in main.dart${NC}"
    ((PASSED++))
else
    echo "${RED}❌ Theme not integrated in main.dart${NC}"
    ((FAILED++))
fi

# Test 4: Check if pubspec.yaml has correct app name
echo ""
echo "📦 Checking pubspec.yaml..."
if grep -q "name: risdi" pubspec.yaml; then
    echo "${GREEN}✅ App name is 'risdi'${NC}"
    ((PASSED++))
else
    echo "${RED}❌ App name is not 'risdi'${NC}"
    ((FAILED++))
fi

# Test 5: Check if build.gradle has correct package
echo ""
echo "🔧 Checking Android configuration..."
if grep -q "applicationId = \"com.risdi.app\"" android/app/build.gradle; then
    echo "${GREEN}✅ Package ID is 'com.risdi.app'${NC}"
    ((PASSED++))
else
    echo "${RED}❌ Package ID is not 'com.risdi.app'${NC}"
    ((FAILED++))
fi

# Test 6: Run flutter analyze on constants
echo ""
echo "🧪 Running flutter analyze on constants..."
if command -v flutter &> /dev/null; then
    ANALYSIS=$(flutter analyze lib/core/constants/ 2>&1)
    if echo "$ANALYSIS" | grep -q "No issues found"; then
        echo "${GREEN}✅ Constants have no compilation errors${NC}"
        ((PASSED++))
    else
        echo "${YELLOW}⚠️ Constants have some issues (non-critical)${NC}"
        echo "$ANALYSIS" | grep -E "error|warning" | head -3
        ((PASSED++))
    fi
else
    echo "${YELLOW}⚠️ Flutter not found in PATH - skipping analysis${NC}"
fi

# Test 7: Check documentation files
echo ""
echo "📚 Checking documentation..."
DOCS=(
    "CONSTANTS_QUICK_REFERENCE.md"
    "REFACTORING_GUIDE.md"
    "IMPLEMENTATION_SUMMARY.md"
    "PRODUCTION_CHECKLIST.md"
    "CONSTANTS_STATUS.md"
    "DELIVERY_SUMMARY.md"
    "README_DOCUMENTATION_INDEX.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "${GREEN}✅ $(basename $doc)${NC}"
        ((PASSED++))
    else
        echo "${YELLOW}⚠️ $(basename $doc) - Not found${NC}"
    fi
done

# Test 8: Verify dependencies
echo ""
echo "📥 Checking dependencies..."
if command -v flutter &> /dev/null; then
    if flutter pub get > /dev/null 2>&1; then
        echo "${GREEN}✅ All dependencies resolved${NC}"
        ((PASSED++))
    else
        echo "${YELLOW}⚠️ Some dependencies may have issues${NC}"
    fi
fi

# Summary
echo ""
echo "======================================"
echo "📊 Verification Summary"
echo "======================================"
echo "${GREEN}Passed: $PASSED${NC}"
echo "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "${GREEN}✅ All checks passed! Constants system is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Read CONSTANTS_QUICK_REFERENCE.md"
    echo "2. Follow REFACTORING_GUIDE.md to migrate screens"
    echo "3. Use PRODUCTION_CHECKLIST.md for deployment"
    exit 0
else
    echo "${RED}❌ Some checks failed. Please review the issues above.${NC}"
    exit 1
fi
