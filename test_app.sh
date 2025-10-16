#!/bin/bash

echo "清理本地存储缓存..."
rm -rf /home/parski/.local/share/curriculum 2>/dev/null || true
rm -rf /home/parski/.config/curriculum 2>/dev/null || true

echo "运行代码分析..."
flutter analyze

echo "构建应用..."
flutter build linux --debug 2>&1 | grep -E "(Error|error|崩溃|crash)" || echo "构建成功"

echo "测试完成！"
