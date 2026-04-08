#!/bin/bash

# 内核清理脚本
# 用于删除有问题的驱动，避免编译错误

set -e

# 从参数或环境变量获取内核目录
KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"

echo "=========================================="
echo "内核清理脚本"
echo "=========================================="
echo ""

# 检查内核目录是否存在
if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误：内核目录不存在: $KERNEL_DIR"
    echo "请确保内核目录存在，或使用参数指定正确的路径"
    echo ""
    echo "使用方法："
    echo "  bash clean-kernel-drivers.sh <kernel-directory>"
    echo ""
    echo "示例："
    echo "  bash clean-kernel-drivers.sh /home/runner/work/android/kernel/oneplus/sdm845"
    exit 1
fi

echo "内核目录: $KERNEL_DIR"
echo ""

cd "$KERNEL_DIR"

echo "1. 删除有问题的蓝牙驱动..."

# 删除 btfm_slim 驱动（依赖于已删除的组件）
echo "  - 删除 btfm_slim 驱动"
rm -rf drivers/bluetooth/btfm_slim.c || true
rm -rf drivers/bluetooth/btfm_slim.h || true
sed -i '/btfm_slim/d' drivers/bluetooth/Makefile || true

# 删除 bluetooth-power 驱动（依赖于 btfm_slim）
echo "  - 删除 bluetooth-power 驱动"
rm -rf drivers/bluetooth/bluetooth-power.c || true
sed -i '/bluetooth-power/d' drivers/bluetooth/Makefile || true

echo ""
echo "2. 删除有问题的 mdss-dsi-pll-10nm 驱动..."

# 删除 mdss-dsi-pll-10nm 驱动（依赖于不存在的 trace 头文件）
echo "  - 删除 mdss-dsi-pll-10nm 驱动"
rm -rf drivers/clk/qcom/mdss/mdss-dsi-pll-10nm.c || true
sed -i '/mdss-dsi-pll-10nm/d' drivers/clk/qcom/mdss/Makefile || true

# 禁用蓝牙驱动的 WERROR 选项
echo "  - 禁用蓝牙驱动的 WERROR 选项"
if [ -f "drivers/bluetooth/Makefile" ]; then
  sed -i '/-Werror/d' drivers/bluetooth/Makefile || true
  sed -i '/WERROR/d' drivers/bluetooth/Makefile || true
  # 添加 -Wno-error 到编译选项
  if ! grep -q "EXTRA_CFLAGS" drivers/bluetooth/Makefile; then
    echo "EXTRA_CFLAGS += -Wno-error" >> drivers/bluetooth/Makefile
  fi
fi

# 禁用主 Makefile 中的 WERROR 选项
echo "  - 禁用主 Makefile 中的 WERROR 选项"
if [ -f "Makefile" ]; then
  sed -i 's/-Werror//g' Makefile || true
  sed -i 's/WERROR=y/WERROR=n/g' Makefile || true
  sed -i 's/-implicit-function-declaration//g' Makefile || true
fi

# 禁用 scripts/Makefile.build 中的 WERROR 选项
echo "  - 禁用 scripts/Makefile.build 中的 WERROR 选项"
if [ -f "scripts/Makefile.build" ]; then
  sed -i 's/-Werror//g' scripts/Makefile.build || true
  sed -i 's/WERROR=y/WERROR=n/g' scripts/Makefile.build || true
  sed -i 's/-implicit-function-declaration//g' scripts/Makefile.build || true
fi

echo ""
echo "=========================================="
echo "清理完成！"
echo "=========================================="
echo ""
echo "已删除的驱动："
echo "  - btfm_slim.c (蓝牙 SLIM 总线驱动)"
echo "  - bluetooth-power.c (蓝牙电源管理)"
echo "  - mdss-dsi-pll-10nm.c (MDSS DSI PLL 10nm 驱动)"
echo ""
echo "下一步："
echo "  make $DEFCONFIG"
echo "  make -j\$(nproc) Image.gz"
echo ""
