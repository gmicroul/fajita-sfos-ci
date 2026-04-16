#!/bin/bash

# 真实摄像头驱动头文件修复脚本
# 从VerdandiTeam仓库下载真实头文件

set -e

KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"
REPO_BASE="https://raw.githubusercontent.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable/lineage-16.0"

echo "=========================================="
echo "下载真实摄像头驱动头文件"
echo "=========================================="
echo ""

# 检查内核目录是否存在
if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误：内核目录不存在: $KERNEL_DIR"
    exit 1
fi

echo "内核目录: $KERNEL_DIR"
echo ""

cd "$KERNEL_DIR"

# 下载函数，带重试机制
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=5
    local retry_delay=3
    
    echo "下载: $(basename "$output")"
    
    for attempt in $(seq 1 $max_retries); do
        if curl -s --fail "$url" -o "$output"; then
            if [ -s "$output" ]; then
                echo "  成功下载 (第${attempt}次尝试)"
                return 0
            else
                echo "  警告：下载的文件为空"
                rm -f "$output"
            fi
        fi
        
        if [ $attempt -lt $max_retries ]; then
            echo "  第${attempt}次下载失败，${retry_delay}秒后重试..."
            sleep $retry_delay
        fi
    done
    
    echo "  错误：无法下载文件"
    return 1
}

echo "下载摄像头驱动核心头文件..."

# 要下载的文件列表 (camera 目录)
declare -A files
files["drivers/media/platform/msm/camera/cam_core/cam_context.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_core/cam_context.h"
files["drivers/media/platform/msm/camera/cam_utils/cam_debug_util.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_utils/cam_debug_util.h"
files["drivers/media/platform/msm/camera/cam_core/cam_node.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_core/cam_node.h"
files["drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"
files["drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"
files["drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_core.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_core.h"

# camera_oneplus 目录的相同文件
files["drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_core/cam_context.h"
files["drivers/media/platform/msm/camera_oneplus/cam_utils/cam_debug_util.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_utils/cam_debug_util.h"
files["drivers/media/platform/msm/camera_oneplus/cam_core/cam_node.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_core/cam_node.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"
files["drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_core.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_core.h"

# 其他必要的头文件
files["drivers/media/platform/msm/camera/cam_utils/cam_trace.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_utils/cam_trace.h"
files["drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_utils/cam_trace.h"
files["drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_interface.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_interface.h"
files["drivers/media/platform/msm/camera/cam_hw_mgr_intf.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_hw_mgr_intf.h"
files["drivers/media/platform/msm/camera_oneplus/cam_req_mgr/cam_req_mgr_interface.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_interface.h"
files["drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_core.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_core.h"
files["drivers/media/platform/msm/camera_oneplus/cam_req_mgr/cam_req_mgr_core.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_core.h"
files["drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_util.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_util.h"
files["drivers/media/platform/msm/camera_oneplus/cam_req_mgr/cam_req_mgr_util.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_util.h"

# ISP packet parser和相关头文件
files["drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"
files["drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"

echo "下载文件列表："
for output_path in "${!files[@]}"; do
    echo "  - $(basename "$output_path")"
done
echo ""

# 下载所有文件
success_count=0
fail_count=0

for output_path in "${!files[@]}"; do
    url="${files[$output_path]}"
    
    if download_with_retry "$url" "$output_path"; then
        success_count=$((success_count + 1))
    else
        fail_count=$((fail_count + 1))
        echo "创建基本头文件作为回退..."
        mkdir -p "$(dirname "$output_path")"
        
        # 创建最基本的头文件
        header_name=$(basename "$output_path" .h | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        cat > "$output_path" << EOF
#ifndef _${header_name}_H
#define _${header_name}_H

#include <linux/types.h>

#endif /* _${header_name}_H */
EOF
    fi
done

echo ""
echo "下载统计："
echo "  成功: $success_count"
echo "  失败: $fail_count"

# 修复路径引用
echo ""
echo "修复头文件引用路径..."

# cam_context.h 需要包含其他头文件
if [ -f "drivers/media/platform/msm/camera/cam_core/cam_context.h" ]; then
    echo "修复 camera/cam_core/cam_context.h..."
    sed -i 's|#include "cam_req_mgr_interface.h"|#include "../cam_req_mgr/cam_req_mgr_interface.h"|g' \
        drivers/media/platform/msm/camera/cam_core/cam_context.h || true
fi

if [ -f "drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h" ]; then
    echo "修复 camera_oneplus/cam_core/cam_context.h..."
    sed -i 's|#include "cam_req_mgr_interface.h"|#include "../cam_req_mgr/cam_req_mgr_interface.h"|g' \
        drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h || true
fi

# 确保cam_debug_util.h存在
if [ ! -f "drivers/media/platform/msm/camera/cam_utils/cam_debug_util.h" ]; then
    echo "创建cam_debug_util.h..."
    mkdir -p drivers/media/platform/msm/camera/cam_utils
    cat > drivers/media/platform/msm/camera/cam_utils/cam_debug_util.h << 'EOF'
#ifndef _CAM_DEBUG_UTIL_H
#define _CAM_DEBUG_UTIL_H

#define CAM_ERR(module, fmt, args...) printk(KERN_ERR "%s: " fmt, module, ##args)
#define CAM_WARN(module, fmt, args...) printk(KERN_WARNING "%s: " fmt, module, ##args)
#define CAM_INFO(module, fmt, args...) printk(KERN_INFO "%s: " fmt, module, ##args)
#define CAM_DBG(module, fmt, args...) printk(KERN_DEBUG "%s: " fmt, module, ##args)

#endif /* _CAM_DEBUG_UTIL_H */
EOF
    cp drivers/media/platform/msm/camera/cam_utils/cam_debug_util.h \
       drivers/media/platform/msm/camera_oneplus/cam_utils/cam_debug_util.h
fi

# 修复cam_trace.h中的路径问题
echo "修复cam_trace.h中的路径问题..."
if [ -f "drivers/media/platform/msm/camera/cam_utils/cam_trace.h" ]; then
    echo "修复camera/cam_utils/cam_trace.h..."
    # 替换#include "cam_context.h"为#include "../cam_core/cam_context.h"
    sed -i 's|#include "cam_context.h"|#include "../cam_core/cam_context.h"|g' \
        drivers/media/platform/msm/camera/cam_utils/cam_trace.h || true
fi

if [ -f "drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h" ]; then
    echo "修复camera_oneplus/cam_utils/cam_trace.h..."
    sed -i 's|#include "cam_context.h"|#include "../cam_core/cam_context.h"|g' \
        drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h || true
fi

# 修复cam_isp_packet_parser.h中的路径
echo "修复cam_isp_packet_parser.h中的路径..."
if [ -f "drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h" ]; then
    echo "修复camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h..."
    # 从hw_utils/include/到isp_hw_mgr/的相对路径是../../
    sed -i 's|#include "cam_ife_hw_mgr.h"|#include "../../cam_ife_hw_mgr.h"|g' \
        drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h || true
    sed -i 's|#include "cam_isp_hw_mgr.h"|#include "../../cam_isp_hw_mgr.h"|g' \
        drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h || true
fi

if [ -f "drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h" ]; then
    echo "修复camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h..."
    sed -i 's|#include "cam_ife_hw_mgr.h"|#include "../../cam_ife_hw_mgr.h"|g' \
        drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h || true
    sed -i 's|#include "cam_isp_hw_mgr.h"|#include "../../cam_isp_hw_mgr.h"|g' \
        drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h || true
fi

echo ""
echo "=========================================="
echo "真实头文件修复完成！"
echo "=========================================="
echo ""
echo "使用真实头文件修复编译错误，保留摄像头功能"
echo "头文件来自: $REPO_BASE"
echo ""
echo "注意：如果网络下载失败，会创建基本头文件"
echo "但这可能影响摄像头功能的完整性"
echo ""
echo "下一步："
echo " make \$DEFCONFIG"
echo " make -j\$(nproc) Image.gz KCFLAGS=\"-Wno-error -fno-stack-protector -mcmodel=large\""
echo ""