#!/bin/bash

# 创建空的 trace 头文件以修复编译错误

set -e

# 从参数或环境变量获取内核目录
KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"

echo "=========================================="
echo "创建空的 trace 头文件"
echo "=========================================="
echo ""

# 检查内核目录是否存在
if [ ! -d "$KERNEL_DIR" ]; then
 echo "错误：内核目录不存在: $KERNEL_DIR"
 echo "请确保内核目录存在，或使用参数指定正确的路径"
 echo ""
 echo "使用方法："
 echo " bash create-empty-trace-headers.sh <kernel-directory>"
 echo ""
 echo "示例："
 echo " bash create-empty-trace-headers.sh /home/runner/work/android/kernel/oneplus/sdm845"
 exit 1
fi

echo "内核目录: $KERNEL_DIR"
echo ""

echo "创建空的 trace 头文件..."

# 创建 mdss_pll_trace.h
mkdir -p "$KERNEL_DIR/drivers/clk/qcom/mdss"
echo " - 创建 drivers/clk/qcom/mdss/mdss_pll_trace.h"
cat > "$KERNEL_DIR/drivers/clk/qcom/mdss/mdss_pll_trace.h" << 'EOF'
/* Empty trace header file to fix compilation error */
/* This file is needed for mdss-dsi-pll-10nm.c compilation */

#undef TRACE_SYSTEM
#define TRACE_SYSTEM mdss_pll

#if !defined(_MDSS_PLL_TRACE_H) || defined(TRACE_HEADER_MULTI_READ)
#define _MDSS_PLL_TRACE_H

#include <linux/tracepoint.h>

#endif /* _MDSS_PLL_TRACE_H */

/* This part must be outside protection */
#undef TRACE_INCLUDE_PATH
#define TRACE_INCLUDE_PATH ../../..  /* Go up 3 levels from drivers/clk/qcom/mdss/ to root, then to include/trace/events */
#include <trace/define_trace.h>
EOF

# 注意：fix-mdss-pll-trace.sh已经创建了 include/trace/events/mdss_pll.h
# 这里我们只需要创建 mdss_pll_trace.h
# TRACE_INCLUDE_PATH设置为../../..，所以会从drivers/clk/qcom/mdss/
# 向上三级到根目录，然后找到include/trace/events/mdss_pll.h

echo ""
echo "=========================================="
echo "创建完成！"
echo "=========================================="
echo ""
echo "已创建的文件："
echo " - drivers/clk/qcom/mdss/mdss_pll_trace.h"
echo ""
echo "注意：fix-mdss-pll-trace.sh会创建include/trace/events/mdss_pll.h文件"
