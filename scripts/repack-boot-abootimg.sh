#!/bin/bash
# 使用 abootimg 重新打包 boot.img（更可靠）

set -e

if [ -z "$1" ]; then
    echo "用法: $0 <原厂boot.img> <新内核Image.gz> <输出boot.img>"
    exit 1
fi

ORIGINAL_BOOT="$1"
NEW_KERNEL="$2"
OUTPUT_BOOT="$3"

if [ ! -f "$ORIGINAL_BOOT" ]; then
    echo "错误: 原厂 boot.img 不存在: $ORIGINAL_BOOT"
    exit 1
fi

if [ ! -f "$NEW_KERNEL" ]; then
    echo "错误: 新内核不存在: $NEW_KERNEL"
    exit 1
fi

echo "=== 使用 abootimg 重新打包 boot.img ==="
echo ""

# 创建临时目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# 解包原厂 boot.img
echo "1. 解包原厂 boot.img..."
cd $TEMP_DIR
abootimg -x "$ORIGINAL_BOOT" bootimg.cfg zImage initrd.img dtb 2>&1 || true

# 显示原厂配置
echo ""
echo "2. 原厂 boot.img 配置:"
echo "====================="
if [ -f "bootimg.cfg" ]; then
    cat bootimg.cfg
else
    echo "警告: 无法提取 bootimg.cfg"
    exit 1
fi

# 备份原厂内核
echo ""
echo "3. 备份原厂内核..."
if [ -f "zImage" ]; then
    cp zImage zImage.original
    echo "原厂内核大小: $(ls -lh zImage.original | awk '{print $5}')"
fi

# 替换内核
echo ""
echo "4. 替换内核..."
cp "$NEW_KERNEL" zImage
echo "新内核大小: $(ls -lh zImage | awk '{print $5}')"

# 重新打包
echo ""
echo "5. 重新打包 boot.img..."
abootimg --create "$OUTPUT_BOOT" -f bootimg.cfg -k zImage -r initrd.img -s dtb 2>&1 || true

# 验证
echo ""
echo "6. 验证新 boot.img..."
if [ -f "$OUTPUT_BOOT" ]; then
    echo "新 boot.img 大小: $(ls -lh "$OUTPUT_BOOT" | awk '{print $5}')"
    echo "新 boot.img 信息:"
    abootimg -i "$OUTPUT_BOOT" 2>&1 || true
else
    echo "错误: 无法创建新 boot.img"
    exit 1
fi

echo ""
echo "=== 打包完成 ==="
echo "输出文件: $OUTPUT_BOOT"
