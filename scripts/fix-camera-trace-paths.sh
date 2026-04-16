#!/bin/bash

# 摄像头trace头文件路径修复脚本
# 专门修复cam_trace.h中的错误相对路径引用

set -e

KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"

echo "=========================================="
echo "修复摄像头trace头文件路径问题"
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

echo "修复cam_trace.h中的相对路径引用..."

# 函数：修复单个cam_trace.h文件
fix_cam_trace() {
    local file="$1"
    local cam_type="$2"  # camera 或 camera_oneplus
    
    if [ ! -f "$file" ]; then
        echo "文件不存在: $file"
        return 1
    fi
    
    echo "修复: $file"
    
    # 备份原始文件
    cp "$file" "${file}.backup"
    
    # cam_trace.h的位置: drivers/media/platform/msm/{camera|camera_oneplus}/cam_utils/cam_trace.h
    # 它需要包含的头文件可能在:
    # - ../cam_core/cam_context.h
    # - ../cam_req_mgr/cam_req_mgr_interface.h
    # - ../cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h (这个可能需要更多层目录)
    
    # 修复常见包含路径
    sed -i '
        # cam_context.h -> ../cam_core/cam_context.h
        s|#include "cam_context.h"|#include "../cam_core/cam_context.h"|g
        
        # cam_req_mgr_interface.h -> ../cam_req_mgr/cam_req_mgr_interface.h
        s|#include "cam_req_mgr_interface.h"|#include "../cam_req_mgr/cam_req_mgr_interface.h"|g
        
        # cam_isp_hw_mgr.h -> ../cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h
        s|#include "cam_isp_hw_mgr.h"|#include "../cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"|g
        
        # cam_ife_hw_mgr.h -> ../cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h
        s|#include "cam_ife_hw_mgr.h"|#include "../cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"|g
        
        # cam_sensor_core.h -> ../cam_sensor_module/cam_sensor_core.h
        s|#include "cam_sensor_core.h"|#include "../cam_sensor_module/cam_sensor_core.h"|g
    ' "$file"
    
    # 显示修改的行
    echo "修改的行:"
    grep -n '#include' "$file" || echo "没有找到#include语句"
}

# 修复camera目录下的cam_trace.h
fix_cam_trace "drivers/media/platform/msm/camera/cam_utils/cam_trace.h" "camera"

# 修复camera_oneplus目录下的cam_trace.h
fix_cam_trace "drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h" "camera_oneplus"

echo ""
echo "同时修复其他可能引用错误的地方..."

# 检查cam_context_utils.c是否需要修复
if [ -f "drivers/media/platform/msm/camera/cam_core/cam_context_utils.c" ]; then
    echo "检查cam_context_utils.c..."
    # 这个文件可能包含cam_trace.h，而cam_trace.h又包含cam_context.h
    # 实际上，问题可能在于cam_context_utils.c包含cam_trace.h，而cam_trace.h包含错误的cam_context.h路径
    # 我们已经修复了cam_trace.h，所以这个问题应该解决了
fi

echo ""
echo "=========================================="
echo "cam_trace.h路径修复完成！"
echo "=========================================="
echo ""
echo "修复的内容："
echo "1. cam_context.h -> ../cam_core/cam_context.h"
echo "2. cam_req_mgr_interface.h -> ../cam_req_mgr/cam_req_mgr_interface.h"
echo "3. cam_isp_hw_mgr.h -> ../cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"
echo "4. cam_ife_hw_mgr.h -> ../cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"
echo "5. cam_sensor_core.h -> ../cam_sensor_module/cam_sensor_core.h"
echo ""
echo "注意：如果头文件确实不存在，编译仍会失败"
echo "但这通常是因为real-camera-headers-fix.sh没有正确下载所有文件"
echo ""
