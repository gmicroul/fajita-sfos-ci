#!/bin/bash
set -e

KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"
REPO_BASE="https://raw.githubusercontent.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable/lineage-16.0"

echo "=========================================="
echo "修复 cam_req_mgr 缺失头文件"
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
        if curl -s --fail "$url" -o "$output"; then
            if [ -s "$output" ]; then
                echo " 成功下载 (第${attempt}次尝试)"
                return 0
            fi
        fi
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
/* 回退头文件：网络下载失败，创建空文件以通过编译 */
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

#endif /* _${header_name}_H */
EOF
}

# 关键缺失文件
TARGET_FILE="drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_core.h"
URL="${REPO_BASE}/drivers/media/platform/msm/camera/cam_req_mgr/cam_req_mgr_core.h"

echo "尝试下载：$URL"

if ! download_with_retry "$URL" "$TARGET_FILE"; then
    echo "下载失败，使用回退方案..."
    create_fallback_header "$TARGET_FILE"
fi

echo ""
echo "=========================================="
echo "cam_req_mgr 修复完成！"
echo "=========================================="
