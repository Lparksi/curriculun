#!/bin/bash

# ========================================
# 版本号同步检查脚本
# 用途：验证 pubspec.yaml 和 version_code.txt 是否同步
# ========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📋 版本号同步检查${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 从 pubspec.yaml 读取版本
PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
PUBSPEC_VERSION_NAME=$(echo "$PUBSPEC_VERSION" | cut -d'+' -f1)
PUBSPEC_VERSION_CODE=$(echo "$PUBSPEC_VERSION" | cut -d'+' -f2)

echo -e "${BLUE}📄 pubspec.yaml:${NC}"
echo "  完整版本: $PUBSPEC_VERSION"
echo "  版本名称: $PUBSPEC_VERSION_NAME"
echo "  版本代码: $PUBSPEC_VERSION_CODE"
echo ""

# 2. 从 version_code.txt 读取版本
VERSION_CODE_FILE="android/version_code.txt"
if [[ -f "$VERSION_CODE_FILE" ]]; then
    STORED_VERSION_CODE=$(cat "$VERSION_CODE_FILE" | tr -d ' \n')
    echo -e "${BLUE}📄 android/version_code.txt:${NC}"
    echo "  版本代码: $STORED_VERSION_CODE"
    echo ""
else
    echo -e "${YELLOW}⚠️  警告: android/version_code.txt 不存在${NC}"
    STORED_VERSION_CODE="0"
fi

# 3. 比较版本号
echo -e "${BLUE}🔍 同步检查:${NC}"
if [[ "$PUBSPEC_VERSION_CODE" == "$STORED_VERSION_CODE" ]]; then
    echo -e "${GREEN}✅ 版本号同步正常${NC}"
    echo ""
    SYNC_STATUS=0
else
    echo -e "${RED}❌ 版本号不同步！${NC}"
    echo -e "${YELLOW}  pubspec.yaml 版本代码: $PUBSPEC_VERSION_CODE${NC}"
    echo -e "${YELLOW}  version_code.txt 版本代码: $STORED_VERSION_CODE${NC}"
    echo ""
    SYNC_STATUS=1
fi

# 4. 显示下一个版本号
NEXT_VERSION_CODE=$((PUBSPEC_VERSION_CODE > STORED_VERSION_CODE ? PUBSPEC_VERSION_CODE + 1 : STORED_VERSION_CODE + 1))
echo -e "${BLUE}🚀 下次构建版本:${NC}"
echo "  版本名称: $PUBSPEC_VERSION_NAME"
echo "  版本代码: $NEXT_VERSION_CODE"
echo "  完整版本: ${PUBSPEC_VERSION_NAME}+${NEXT_VERSION_CODE}"
echo ""

# 5. 提供修复建议
if [[ $SYNC_STATUS -ne 0 ]]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}💡 修复建议:${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "运行以下命令同步版本号："
    echo ""
    MAX_VERSION_CODE=$((PUBSPEC_VERSION_CODE > STORED_VERSION_CODE ? PUBSPEC_VERSION_CODE : STORED_VERSION_CODE))
    echo -e "${GREEN}# 同步到最大版本号 $MAX_VERSION_CODE${NC}"
    echo "echo \"$MAX_VERSION_CODE\" > android/version_code.txt"
    echo "sed -i 's/^version:.*/version: ${PUBSPEC_VERSION_NAME}+${MAX_VERSION_CODE}/' pubspec.yaml"
    echo ""
    echo "或者使用自动同步脚本："
    echo -e "${GREEN}./scripts/sync_version.sh${NC}"
    echo ""
fi

# 6. 显示 Git 状态
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📝 Git 状态:${NC}"
echo -e "${BLUE}========================================${NC}"
git status --short pubspec.yaml android/version_code.txt 2>/dev/null || echo "没有未提交的版本文件变更"
echo ""

# 返回状态码
exit $SYNC_STATUS
