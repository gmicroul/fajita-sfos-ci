#!/bin/bash
# 诊断 boot.img 问题

set -e

echo "=== Boot.img 诊断工具 ==="
echo ""

# 检查是否安装了必要的工具
if ! command -v abootimg &> /dev/null; then
    echo "错误: abootimg 未安装"
    echo "安装: sudo apt-get install abootimg"
    exit 1
fi

if [ -z "$1" ]; then
    echo "用法: $0 <boot.img>"
    exit 1
fi

BOOT_IMG="$1"

if [ ! -f "$BOOT_IMG" ]; then
    echo "错误: 文件不存在: $BOOT_IMG"
    exit 1
fi

echo "分析文件: $BOOT_IMG"
echo ""

# 创建临时目录
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# 解包 boot.img
echo "1. 解包 boot.img..."
cd $TEMP_DIR
abootimg -x "$BOOT_IMG" bootimg.cfg zImage initrd.img dtb 2>&1 || true

# 显示 boot.img 信息
echo ""
echo "2. Boot.img 配置:"
echo "=================="
if [ -f "bootimg.cfg" ]; then
    cat bootimg.cfg
else
    echo "警告: 无法提取 bootimg.cfg"
fi

# 检查内核
echo ""
echo "3. 内核信息:"
echo "============"
if [ -f "zImage" ]; then
    echo "大小: $(ls -lh zImage | awk '{print $5}')"
    echo "类型: $(file zImage 2>/dev/null || echo "无法识别")"

    # 检查是否是压缩的
    if file zImage 2>/dev/null | grep -q "gzip"; then
        echo "格式: gzip 压缩 (Image.gz)"
    elif file zImage 2>/dev/null | grep -q "LZMA"; then
        echo "格式: LZMA 压缩"
    elif file zImage 2>/dev/null | grep -q "LZ4"; then
        echo "格式: LZ4 压缩"
    else
        echo "格式: 未压缩或未知格式"
    fi
else
    echo "警告: 无法提取 zImage"
fi

# 检查 ramdisk
echo ""
echo "4. Ramdisk 信息:"
echo "==============="
if [ -f "initrd.img" ]; then
    echo "大小: $(ls -lh initrd.img | awk '{print $5}')"
    echo "类型: $(file initrd.img 2>/dev/null || echo "无法识别")"
else
    echo "警告: 无法提取 initrd.img"
fi

# 检查设备树
echo ""
echo "5. 设备树信息:"
echo "============="
if [ -f "dtb" ]; then
    echo "大小: $(ls -lh dtb | awk '{print $5}')"
    echo "类型: $(file dtb 2>/dev/null || echo "无法识别")"

    # 尝试解析设备树
    if command -v dtc &> /dev/null; then
        echo ""
        echo "设备树模型:"
        dtc -I dtb -O dts dtb 2>/dev/null | grep -E "model|compatible" | head -5 || true
    fi
else
    echo "警告: 无法提取 dtb"
fi

# 检查 boot.img 头部
echo ""
echo "6. Boot.img 头部信息:"
echo "===================="
abootimg -i "$BOOT_IMG" 2>&1 || echo "无法读取头部信息"

echo ""
echo "=== 诊断完成 ==="
