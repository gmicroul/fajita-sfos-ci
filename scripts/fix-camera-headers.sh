#!/bin/bash
set -e

KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"
REPO_BASE="https://raw.githubusercontent.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable/lineage-16.0"

echo "=========================================="
echo "修复摄像头驱动缺失的头文件"
echo "=========================================="

if [ ! -d "$KERNEL_DIR" ]; then
    echo "错误：内核目录不存在：$KERNEL_DIR"
    exit 1
fi

cd "$KERNEL_DIR"

download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_delay=5
    
    echo "下载：$(basename "$output")"
    for attempt in $(seq 1 $max_retries); do
        if curl -s --fail -L "$url" -o "$output"; then
            if [ -s "$output" ]; then
                echo " 成功下载 (第${attempt}次尝试)"
                return 0
            fi
        fi
        echo " 尝试 ${attempt}/${max_retries} 失败，等待 ${retry_delay}s..."
        if [ $attempt -lt $max_retries ]; then
            sleep $retry_delay
        fi
    done
    return 1
}

create_fallback_header() {
    local file="$1"
    local header_name="$(basename "$file" .h | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
    echo "创建回退头文件：$(basename "$file")"
    mkdir -p "$(dirname "$file")"
    
    cat > "$file" << EOF
/* 回退头文件：网络下载失败，创建最小化定义以通过编译 */
#ifndef _${header_name}_H
#define _${header_name}_H

#include <linux/types.h>
#include <linux/ioctl.h>

/* Forward declarations */
struct cam_req_mgr_dev;
struct cam_req_mgr_proxy_info;
struct cam_req_mgr_request_info;
struct cam_req_mgr_session_cfg;
struct cam_req_mgr_buf_info;
struct cam_req_mgr_core_data;

/* Basic type definitions */
typedef struct {
    uint32_t session_id;
    uint32_t dev_handle;
    uint32_t reserved;
} cam_req_mgr_session_info_t;

/* IOCTL commands */
#define CAM_REQ_MGR_DEV_NAME "cam_req_mgr"
#define CAM_REQ_MGR_SETUP_DEV _IOW('M', 1, struct cam_req_mgr_proxy_info)
#define CAM_REQ_MGR_RELEASE_DEV _IOW('M', 2, struct cam_req_mgr_request_info)

/* Function prototypes */
int cam_req_mgr_init(void);
void cam_req_mgr_exit(void);

#endif /* _${header_name}_H */
EOF
}

# 1. 修复 cam_req_mgr_core.h
TARGET_FILE="drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_core.h"
URL="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_core.h"

echo "尝试下载：cam_req_mgr_core.h"
if ! download_with_retry "$URL" "$TARGET_FILE"; then
    echo "下载失败，使用回退方案..."
    create_fallback_header "$TARGET_FILE"
fi

# 在 cam_utils 目录创建副本
CAM_UTILS_DIR="drivers/media/platform/msm/camera/cam_utils"
CAM_REQ_MGR_DIR="drivers/media/platform/msm/camera/cam_req_mgr"
if [ -f "$CAM_REQ_MGR_DIR/cam_req_mgr_core.h" ] && [ ! -f "$CAM_UTILS_DIR/cam_req_mgr_core.h" ]; then
    echo "在 cam_utils 目录创建 cam_req_mgr_core.h 副本..."
    cp "$CAM_REQ_MGR_DIR/cam_req_mgr_core.h" "$CAM_UTILS_DIR/cam_req_mgr_core.h"
fi

# 2. 修复 cam_cci_dev.h
TARGET_FILE="drivers/media/platform/msm/camera/cam_sensor_module/cam_cci/cam_cci_dev.h"
URL="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_cci/cam_cci_dev.h"

echo "尝试下载：cam_cci_dev.h"
if ! download_with_retry "$URL" "$TARGET_FILE"; then
    echo "下载失败，使用回退方案..."
    create_fallback_header "$TARGET_FILE"
fi

# 在 cam_sensor_io 目录创建副本
CAM_SENSOR_IO_DIR="drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_io"
CAM_CCI_DIR="drivers/media/platform/msm/camera/cam_sensor_module/cam_cci"
if [ -f "$CAM_CCI_DIR/cam_cci_dev.h" ] && [ ! -f "$CAM_SENSOR_IO_DIR/cam_cci_dev.h" ]; then
    echo "在 cam_sensor_io 目录创建 cam_cci_dev.h 副本..."
    cp "$CAM_CCI_DIR/cam_cci_dev.h" "$CAM_SENSOR_IO_DIR/cam_cci_dev.h"
fi

echo ""
echo "=========================================="
echo "摄像头驱动头文件修复完成！"
echo "=========================================="
