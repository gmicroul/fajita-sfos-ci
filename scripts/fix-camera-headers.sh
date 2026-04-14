#!/bin/bash

# 从VerdandiTeam仓库下载真实的摄像头驱动头文件
# 确保相机功能正常工作

set -e

# 从参数或环境变量获取内核目录
KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"
REPO_BASE="https://raw.githubusercontent.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable/lineage-16.0"

echo "=========================================="
echo "修复摄像头驱动头文件"
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

# 下载缺失的摄像头驱动头文件
echo "下载缺失的摄像头驱动头文件..."

# cam_context.h (两个位置都需要)
mkdir -p drivers/media/platform/msm/camera_oneplus/cam_core
curl -s "$REPO_BASE/drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h" -o drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h

# 同时复制到camera目录
mkdir -p drivers/media/platform/msm/camera/cam_core
cp drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h drivers/media/platform/msm/camera/cam_core/cam_context.h

# cam_ife_hw_mgr.h
mkdir -p drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr
curl -s "$REPO_BASE/drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h" -o drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h

# cam_isp_hw_mgr.h
curl -s "$REPO_BASE/drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h" -o drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h

# cam_sensor_core.h
mkdir -p drivers/media/platform/msm/camera_oneplus/cam_sensor_module
curl -s "$REPO_BASE/drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_core.h" -o drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_core.h

# 修复头文件引用路径
echo "修复头文件引用路径..."

# 修复cam_trace.h中的引用 (camera目录)
if [ -f "drivers/media/platform/msm/camera/cam_utils/cam_trace.h" ]; then
 sed -i 's|#include "cam_context.h"|#include "../cam_core/cam_context.h"|g' drivers/media/platform/msm/camera/cam_utils/cam_trace.h
fi

# 修复cam_trace.h中的引用 (camera_oneplus目录)
if [ -f "drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h" ]; then
 sed -i 's|#include "cam_context.h"|#include "../cam_core/cam_context.h"|g' drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h
fi

# 修复cam_isp_packet_parser.h中的引用
if [ -f "drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h" ]; then
 sed -i 's|#include "cam_ife_hw_mgr.h"|#include "../cam_ife_hw_mgr.h"|g' drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h
fi

echo ""
echo "=========================================="
echo "头文件修复完成！"
echo "=========================================="
echo ""
echo "已下载的头文件："
echo " - cam_context.h"
echo " - cam_ife_hw_mgr.h"
echo " - cam_isp_hw_mgr.h"
echo " - cam_sensor_core.h"
echo ""
echo "这些是真实的头文件，确保相机功能正常"
echo ""