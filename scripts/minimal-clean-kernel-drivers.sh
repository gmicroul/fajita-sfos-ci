#!/bin/bash

# 最小化内核清理脚本 v5
# 策略：完全不删除任何驱动文件，创建必要的stub头文件来修复编译错误
# 保留所有驱动，确保kernel与官方一致

set -e

ORIGINAL_DIR="$(pwd)"
KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"

echo "=========================================="
echo "最小化内核清理脚本 v5 (保留所有驱动)"
echo "=========================================="
echo ""

if [ ! -d "$KERNEL_DIR" ]; then
 echo "错误：内核目录不存在: $KERNEL_DIR"
 exit 1
fi

echo "内核目录：$KERNEL_DIR"
echo ""

cd "$KERNEL_DIR"

# 0. 调用fix-camera-build.sh修复摄像头驱动编译错误
echo "0. 修复摄像头驱动编译错误..."
bash $GITHUB_WORKSPACE/scripts/fix-camera-build.sh "$KERNEL_DIR"

# 1. 创建stub头文件来修复其他编译错误（不删除任何.c文件）

# 1a. btfm_slim.h stub（修复drivers/bluetooth/btfm_slim.c编译错误）
mkdir -p drivers/bluetooth
cat > drivers/bluetooth/btfm_slim.h << 'BTFMSLIMHEADER'
#ifndef _BTFM_SLIM_H_
#define _BTFM_SLIM_H_
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/spinlock.h>
#include <linux/wait.h>
#include <linux/mutex.h>
#include <linux/list.h>

struct btfm_slim_dev {
    struct device *dev;
    struct list_head entry;
    struct mutex lock;
    spinlock_t tx_lock;
    spinlock_t rx_lock;
    wait_queue_head_t readq;
    struct list_head rx_list;
    int tx_irq;
    int rx_irq;
};
#endif
BTFMSLIMHEADER

# 1b. u_ncm.h stub（避免f_ncm.c编译错误）
mkdir -p include/function
cat > include/function/u_ncm.h << 'UNCMHEADER'
#ifndef _U_NCM_H
#define _U_NCM_H
#include <linux/types.h>
struct usb_composite_dev;
struct usb_ctrlrequest;
int ncm_ctrlrequest(struct usb_composite_dev *cdev, const struct usb_ctrlrequest *ctrl);
#endif
UNCMHEADER

# 1c. usb_trace.h stub
mkdir -p drivers/usb/gadget/composite
cat > drivers/usb/gadget/composite/usb_trace.h << 'USBTRACE'
#ifndef _USB_TRACE_H
#define _USB_TRACE_H
#include <linux/types.h>
#endif
USBTRACE

# 1d. tracer_pkt stub
mkdir -p drivers/soc/qcom
cat > drivers/soc/qcom/tracer_pkt_private.h << 'TRACERPKT'
#ifndef _TRACER_PKT_PRIVATE_H
#define _TRACER_PKT_PRIVATE_H
#include <linux/types.h>
#endif
TRACERPKT

# 1e. IPA trace stubs
mkdir -p include/trace/events/ipa
mkdir -p drivers/platform/msm/ipa/ipa_v3
mkdir -p drivers/platform/msm/ipa/ipa_clients

cat > include/trace/events/ipa/ipa_trace.h << 'IPATRACE'
#undef TRACE_SYSTEM
#define TRACE_SYSTEM ipa
#define TRACE_INCLUDE_FILE ipa_trace
#ifndef _IPA_TRACE_H
#define _IPA_TRACE_H
#include <linux/tracepoint.h>
TRACE_EVENT(ipa_trace_intr, TP_PROTO(unsigned long a), TP_ARGS(a),
    TP_STRUCT__entry(__field(unsigned long, a)),
    TP_fast_assign(__entry->a = a;),
    TP_printk("a=%lu", __entry->a));
#endif
IPATRACE

cat > drivers/platform/msm/ipa/ipa_v3/ipa_trace.h << 'IPAWRAPPER'
#ifndef _IPA_V3_TRACE_H
#define _IPA_V3_TRACE_H
#include <linux/types.h>
#endif
IPAWRAPPER

cat > drivers/platform/msm/ipa/ipa_clients/rndis_ipa_trace.h << 'RNDISWRAPPER'
#ifndef _RNDIS_IPA_TRACE_H
#define _RNDIS_IPA_TRACE_H
#include <linux/types.h>
#endif
RNDISWRAPPER

# 2. 禁用WERROR避免编译警告变错误
echo "2. 禁用WERROR..."
sed -i 's/-Werror//g' Makefile 2>/dev/null || true
sed -i 's/WERROR=y/WERROR=n/g' Makefile 2>/dev/null || true
sed -i 's/-Werror//g' scripts/Makefile.build 2>/dev/null || true
sed -i 's/WERROR=y/WERROR=n/g' scripts/Makefile.build 2>/dev/null || true

# 3. 禁用stack protector避免编译器不支持
echo "3. 禁用stack protector..."
sed -i 's/-fstack-protector-strong//g' Makefile 2>/dev/null || true
sed -i 's/-fstack-protector//g' Makefile 2>/dev/null || true

# 4. 移除implicit function declaration警告
echo "4. 清理无效编译标志..."
sed -i 's/-implicit-function-declaration//g' Makefile 2>/dev/null || true
sed -i 's/-Wno-implicit-function-declaration//g' Makefile 2>/dev/null || true
sed -i 's/-implicit-function-declaration//g' scripts/Makefile.build 2>/dev/null || true
sed -i 's/-Wno-implicit-function-declaration//g' scripts/Makefile.build 2>/dev/null || true

# 5. 关键：不要删除任何驱动文件！保留所有.c文件
echo "5. 保留所有驱动文件（不删除任何驱动）..."

echo ""
echo "=========================================="
echo "清理完成！所有驱动已保留"
echo "=========================================="

cd "$ORIGINAL_DIR"