#!/bin/bash

# 修复MDSS PLL编译错误
# 创建空的trace事件头文件来绕过编译错误

set -e

# 从参数或环境变量获取内核目录
KERNEL_DIR="${1:-$(pwd)}"

echo "=========================================="
echo "修复MDSS PLL编译错误"
echo "=========================================="
echo ""
echo "内核目录: $KERNEL_DIR"
echo ""

# 必须无条件覆盖原始文件！原始 mdss_pll_trace.h 包含 #include <trace/define_trace.h>，
# 会导致 define_trace.h 使用 TRACE_INCLUDE_PATH/TRACE_INCLUDE_FILE 回头查找原始文件，
# 路径解析不正确导致 fatal error: ./mdss_pll_trace.h: No such file or directory

# 创建include/trace/events目录 (根据内核标准路径)
mkdir -p "$KERNEL_DIR/include/trace/events"

# 无条件创建空的mdss_pll.h文件
echo "创建空的mdss_pll.h文件..."
cat > "$KERNEL_DIR/include/trace/events/mdss_pll.h" << 'EOF'
/* Empty mdss_pll trace header - trace points disabled for compilation */

#ifndef _TRACE_EVENTS_MDSS_PLL_H
#define _TRACE_EVENTS_MDSS_PLL_H

#endif /* _TRACE_EVENTS_MDSS_PLL_H */
EOF

# 无条件覆盖 mdss_pll_trace.h（原始文件会导致 define_trace.h 路径错误）
echo "覆盖mdss_pll_trace.h为宏stub版本..."
mkdir -p "$KERNEL_DIR/drivers/clk/qcom/mdss"
cat > "$KERNEL_DIR/drivers/clk/qcom/mdss/mdss_pll_trace.h" << 'EOF'
#ifndef _MDSS_PLL_TRACE_H
#define _MDSS_PLL_TRACE_H

/* Stub mdss_pll_trace.h - replaces original that uses define_trace.h
 * Original causes: fatal error: ./mdss_pll_trace.h: No such file or directory
 * because TRACE_INCLUDE_PATH resolves to kernel root, not this directory.
 * This stub provides no-op inline macros for all trace calls. */

/* No-op trace function stubs - satisfy all trace_mdss_pll_xxx() calls */
#define trace_mdss_pll_lock(name, val) do {} while (0)
#define trace_mdss_pll_unlock(name, val) do {} while (0)
#define trace_mdss_pll_vote(name, val) do {} while (0)
#define trace_mdss_pll_unvote(name, val) do {} while (0)
#define trace_mdss_pll_wakeoff(name, val) do {} while (0)
#define trace_mdss_pll_dump(name, val) do {} while (0)

#endif /* _MDSS_PLL_TRACE_H */
EOF

# 禁用CREATE_TRACE_POINTS以避免编译错误
echo "禁用CREATE_TRACE_POINTS..."

# 修复MDSS DSI PLL文件
if [ -f "$KERNEL_DIR/drivers/clk/qcom/mdss/mdss-dsi-pll-10nm.c" ]; then
 echo "修复mdss-dsi-pll-10nm.c..."
 sed -i 's/^#define CREATE_TRACE_POINTS/\/\/#define CREATE_TRACE_POINTS/g' "$KERNEL_DIR/drivers/clk/qcom/mdss/mdss-dsi-pll-10nm.c"
fi

# 修复MDSS DP PLL文件
if [ -f "$KERNEL_DIR/drivers/clk/qcom/mdss/mdss-dp-pll-10nm.c" ]; then
 echo "修复mdss-dp-pll-10nm.c..."
 sed -i 's/^#define CREATE_TRACE_POINTS/\/\/#define CREATE_TRACE_POINTS/g' "$KERNEL_DIR/drivers/clk/qcom/mdss/mdss-dp-pll-10nm.c"
fi

echo ""
echo "=========================================="
echo "MDSS PLL编译错误修复完成！"
echo "=========================================="
echo ""
echo ""
echo "=========================================="
echo "MDSS PLL编译错误修复完成！"
echo "=========================================="
echo ""
echo "已创建空的mdss_pll.h文件 (位于: include/trace/events/)"
echo "已注释掉CREATE_TRACE_POINTS定义"
echo ""
echo "这样可以绕过trace事件系统的编译依赖"