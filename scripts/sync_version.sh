#!/bin/bash

# ========================================
# 版本号自动同步脚本
# 用途：统一 pubspec.yaml 和 version_code.txt 的版本号
# ========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔄 版本号自动同步${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. 读取当前版本
PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | tr -d ' ')
PUBSPEC_VERSION_NAME=$(echo "$PUBSPEC_VERSION" | cut -d'+' -f1)
PUBSPEC_VERSION_CODE=$(echo "$PUBSPEC_VERSION" | cut -d'+' -f2)

VERSION_CODE_FILE="android/version_code.txt"
if [[ -f "$VERSION_CODE_FILE" ]]; then
    STORED_VERSION_CODE=$(cat "$VERSION_CODE_FILE" | tr -d ' \n')
else
    STORED_VERSION_CODE="0"
fi

echo "当前状态："
echo "  pubspec.yaml: ${PUBSPEC_VERSION_NAME}+${PUBSPEC_VERSION_CODE}"
echo "  version_code.txt: $STORED_VERSION_CODE"
echo ""

# 2. 确定最终版本号
MAX_VERSION_CODE=$((PUBSPEC_VERSION_CODE > STORED_VERSION_CODE ? PUBSPEC_VERSION_CODE : STORED_VERSION_CODE))

echo -e "${YELLOW}将同步到版本: ${PUBSPEC_VERSION_NAME}+${MAX_VERSION_CODE}${NC}"
echo ""

# 3. 询问用户确认
read -p "是否继续同步？(y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ 同步已取消${NC}"
    exit 1
fi

# 4. 更新文件
echo -e "${BLUE}正在更新文件...${NC}"

# 更新 version_code.txt
echo "$MAX_VERSION_CODE" > "$VERSION_CODE_FILE"
echo -e "${GREEN}✅ 已更新 android/version_code.txt → $MAX_VERSION_CODE${NC}"

# 更新 pubspec.yaml
sed -i "s/^version:.*/version: ${PUBSPEC_VERSION_NAME}+${MAX_VERSION_CODE}/" pubspec.yaml
echo -e "${GREEN}✅ 已更新 pubspec.yaml → ${PUBSPEC_VERSION_NAME}+${MAX_VERSION_CODE}${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 版本号同步完成！${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 5. 显示验证结果
echo "验证结果："
echo "  pubspec.yaml: $(grep '^version:' pubspec.yaml | sed 's/version: //')"
echo "  version_code.txt: $(cat $VERSION_CODE_FILE)"
echo ""

# 6. 提示 Git 提交
echo -e "${YELLOW}💡 建议执行 Git 提交：${NC}"
echo -e "${GREEN}git add pubspec.yaml android/version_code.txt${NC}"
echo -e "${GREEN}git commit -m \"chore: sync version to ${PUBSPEC_VERSION_NAME}+${MAX_VERSION_CODE}\"${NC}"
echo ""
