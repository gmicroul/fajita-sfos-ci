#!/bin/bash

# 从 GitHub Actions 下载编译的设备树

set -e

echo "=========================================="
echo "下载编译的设备树"
echo "=========================================="
echo ""

# 检查参数
if [ -z "$1" ]; then
    echo "使用方法："
    echo "  bash download-dtb.sh <run-id>"
    echo ""
    echo "示例："
    echo "  bash download-dtb.sh 1234567890"
    echo ""
    echo "获取 run-id："
    echo "  1. 访问 GitHub Actions 页面"
    echo "  2. 找到最新的编译任务"
    echo "  3. 点击进入详情"
    echo "  4. URL 中的数字就是 run-id"
    echo ""
    echo "示例 URL："
    echo "  https://github.com/gmicroul/fajita-sfos-ci/actions/runs/1234567890"
    echo "  run-id 就是 1234567890"
    exit 1
fi

RUN_ID="$1"
REPO="gmicroul/fajita-sfos-ci"
ARTIFACT_NAME="boot-fajita-5.0.0.73"

echo "Run ID: $RUN_ID"
echo "Repository: $REPO"
echo "Artifact: $ARTIFACT_NAME"
echo ""

# 检查是否安装了 gh
if ! command -v gh &> /dev/null; then
    echo "错误：未安装 gh CLI"
    echo "请安装："
    echo "  sudo apt-get install -y gh"
    echo "  gh auth login"
    exit 1
fi

# 检查是否已登录
if ! gh auth status &> /dev/null; then
    echo "错误：未登录 GitHub"
    echo "请登录："
    echo "  gh auth login"
    exit 1
fi

echo "1. 下载 boot.img..."
gh run download "$RUN_ID" -R "$REPO" -n "$ARTIFACT_NAME" -D .

if [ ! -f "hybris-boot.img" ]; then
    echo "错误：下载失败，未找到 hybris-boot.img"
    exit 1
fi

echo "  ✓ 下载成功: hybris-boot.img"

echo ""
echo "2. 解包 boot.img..."
mkdir -p hybris-boot-unpack
cd hybris-boot-unpack
mkbootimg --unpack ../hybris-boot.img

if [ -f "dtb" ]; then
    echo "  ✓ 找到设备树文件: dtb"
    cp dtb ../fajita.dtb
else
    echo "  ✗ 未找到设备树文件"
    exit 1
fi

cd ..

echo ""
echo "3. 转换设备树为可读格式..."
dtc -I dtb -O dts -o fajita.dts fajita.dtb

echo "  ✓ 转换成功: fajita.dts"

echo ""
echo "=========================================="
echo "下载完成！"
echo "=========================================="
echo ""
echo "文件列表："
echo "  - hybris-boot.img (boot 镜像)"
echo "  - fajita.dtb (设备树)"
echo "  - fajita.dts (设备树可读格式)"
echo ""
echo "下一步："
echo "  1. 下载原厂 boot.img:"
echo "     wget -O droid-boot.img \\"
echo "       https://github.com/gmicroul/fajita-sfos-ci/releases/download/droid-boot/droid-boot-new.img"
echo ""
echo "  2. 运行设备树检查脚本:"
echo "     bash scripts/check-device-tree.sh"
echo ""
