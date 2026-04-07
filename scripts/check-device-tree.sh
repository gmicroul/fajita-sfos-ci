#!/bin/bash

# 设备树检查脚本
# 用于对比原厂设备树和编译的设备树

set -e

echo "=========================================="
echo "设备树检查脚本"
echo "=========================================="
echo ""

# 检查是否安装了 dtc
if ! command -v dtc &> /dev/null; then
    echo "错误：未安装 dtc 工具"
    echo "请安装：sudo apt-get install -y device-tree-compiler"
    exit 1
fi

# 检查原厂 boot.img
if [ ! -f "droid-boot.img" ]; then
    echo "错误：未找到原厂 boot.img (droid-boot.img)"
    echo "请先下载原厂 boot.img"
    exit 1
fi

# 检查编译的设备树
if [ ! -f "fajita.dtb" ]; then
    echo "错误：未找到编译的设备树 (fajita.dtb)"
    echo "请先从 GitHub Actions 下载编译的设备树"
    exit 1
fi

echo "1. 解包原厂 boot.img..."
mkdir -p droid-boot-unpack
cd droid-boot-unpack
mkbootimg --unpack ../droid-boot.img

# 检查是否有 dtb 文件
if [ -f "dtb" ]; then
    echo "  ✓ 找到原厂设备树文件: dtb"
    cp dtb ../droid-boot.dtb
else
    echo "  ✗ 未找到原厂设备树文件"
    exit 1
fi

cd ..

echo ""
echo "2. 转换原厂设备树为可读格式..."
dtc -I dtb -O dts -o droid-boot.dts droid-boot.dtb

echo ""
echo "3. 转换编译的设备树为可读格式..."
dtc -I dtb -O dts -o fajita.dts fajita.dtb

echo ""
echo "4. 对比设备树..."
echo "=========================================="
echo "原厂设备树信息："
echo "=========================================="
grep -E "model|compatible|qcom,board-id" droid-boot.dts | head -20

echo ""
echo "=========================================="
echo "编译的设备树信息："
echo "=========================================="
grep -E "model|compatible|qcom,board-id" fajita.dts | head -20

echo ""
echo "=========================================="
echo "设备树大小对比："
echo "=========================================="
echo "原厂设备树: $(ls -lh droid-boot.dtb | awk '{print $5}')"
echo "编译的设备树: $(ls -lh fajita.dtb | awk '{print $5}')"

echo ""
echo "=========================================="
echo "设备树节点数量对比："
echo "=========================================="
echo "原厂设备树: $(grep -c "^{" droid-boot.dts) 个节点"
echo "编译的设备树: $(grep -c "^{" fajita.dts) 个节点"

echo ""
echo "=========================================="
echo "关键节点检查："
echo "=========================================="

# 检查关键节点
KEY_NODES=(
    "soc"
    "cpus"
    "memory"
    "timer"
    "interrupt-controller"
    "pmic"
    "gpu"
    "display"
    "bluetooth"
    "wifi"
)

for node in "${KEY_NODES[@]}"; do
    echo ""
    echo "检查节点: $node"
    echo "  原厂: $(grep -c "$node" droid-boot.dts || echo 0) 个"
    echo "  编译: $(grep -c "$node" fajita.dts || echo 0) 个"
done

echo ""
echo "=========================================="
echo "检查完成！"
echo "=========================================="
echo ""
echo "详细设备树文件："
echo "  - droid-boot.dts (原厂)"
echo "  - fajita.dts (编译)"
echo ""
echo "可以手动对比这两个文件，找出差异："
echo "  diff droid-boot.dts fajita.dts"
echo ""
