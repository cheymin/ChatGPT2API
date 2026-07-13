#!/usr/bin/env bash
# 多平台工程目录初始化脚本
#
# 在本地 Flutter SDK 已安装的环境下执行：
#   ./setup_platforms.sh
#
# 该脚本会自动创建 Windows/macOS/Linux/iOS 平台工程目录。
# Android 工程已存在，无需重新创建。
#
# 这是 PiliPlus 多平台支持的关键步骤，CMake/Xcode 工程文件较多，
# 无法通过纯文件写入方式生成，必须用 flutter 命令。

set -e

echo "==> 检查 Flutter 环境"
if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter 命令不存在"
  echo "请先安装 Flutter SDK：https://flutter.dev"
  exit 1
fi
flutter --version

echo ""
echo "==> 创建桌面端平台工程目录（不覆盖 Android）"
flutter create \
  --platforms=windows,macos,linux,ios \
  --org com.cheymin \
  --project-name cilicili \
  --description "CiliCili - 一个第三方哔哩哔哩全平台客户端" \
  .

echo ""
echo "==> 平台目录已创建："
ls -d windows/ macos/ linux/ ios/ 2>/dev/null || true

echo ""
echo "==> 完成！"
echo "现在可以执行："
echo "  flutter run -d windows     # Windows 桌面"
echo "  flutter run -d macos        # macOS 桌面（需 macOS 系统）"
echo "  flutter run -d linux        # Linux 桌面"
echo "  flutter run -d ios          # iOS（需 macOS + Xcode）"
echo "  flutter build windows       # 构建 Windows .exe"
echo "  flutter build macos         # 构建 macOS .app"
echo "  flutter build linux         # 构建 Linux 可执行文件"
