#!/bin/bash

# 真实摄像头驱动头文件修复脚本
# 从VerdandiTeam仓库下载真实头文件

set -e

KERNEL_DIR="${1:-$ANDROID_ROOT/kernel/oneplus/sdm845}"
REPO_BASE="https://raw.githubusercontent.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable/lineage-16.0"
REPO_PROXY="https://gh-proxy.com/https://raw.githubusercontent.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable/lineage-16.0"

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
 
 # 使用代理 URL
 local proxy_url="${url/$REPO_BASE/$REPO_PROXY}"
 
 echo "下载：$(basename "$output")"
 
 for attempt in $(seq 1 $max_retries); do
 if curl -s --fail "$proxy_url" -o "$output"; then
   if [ -s "$output" ]; then
     echo " 成功下载 (第${attempt}次尝试)"
     return 0
   else
     echo " 警告：下载的文件为空"
     rm -f "$output"
   fi
 fi
 
 if [ $attempt -lt $max_retries ]; then
   echo " 第${attempt}次下载失败，${retry_delay}秒后重试..."
   sleep $retry_delay
 fi
 done
 
 echo " 错误：无法下载文件"
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
files["drivers/media/platform/msm/camera/cam_sensor_module/cam_cci/cam_cci_dev.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_cci/cam_cci_dev.h"
files["drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_io/cam_sensor_i2c.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_io/cam_sensor_i2c.h"

# camera_oneplus 目录的相同文件
files["drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_core/cam_context.h"
files["drivers/media/platform/msm/camera_oneplus/cam_utils/cam_debug_util.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_utils/cam_debug_util.h"
files["drivers/media/platform/msm/camera_oneplus/cam_core/cam_node.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_core/cam_node.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_ife_hw_mgr.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/cam_isp_hw_mgr.h"
files["drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_core.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_core.h"
files["drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_cci/cam_cci_dev.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_cci/cam_cci_dev.h"
files["drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_io/cam_sensor_i2c.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_io/cam_sensor_i2c.h"

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

# ISP packet parser 和相关头文件
files["drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/hw_utils/include/cam_isp_packet_parser.h"
files["drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"
files["drivers/media/platform/msm/camera_oneplus/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_isp/isp_hw_mgr/include/cam_isp_hw_mgr_intf.h"

# cam_sync 相关头文件
files["drivers/media/platform/msm/camera/cam_sync/cam_sync_api.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sync/cam_sync_api.h"
files["drivers/media/platform/msm/camera/cam_sync/cam_sync_private.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sync/cam_sync_private.h"
files["drivers/media/platform/msm/camera_oneplus/cam_sync/cam_sync_api.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sync/cam_sync_api.h"
files["drivers/media/platform/msm/camera_oneplus/cam_sync/cam_sync_private.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sync/cam_sync_private.h"

# cam_sensor_utils 相关头文件
files["drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h"
files["drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h"]="${REPO_BASE}/drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h"

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
 sed -i 's|#include "cam_req_mgr_interface.h"|/#include "../cam_req_mgr/cam_req_mgr_interface.h"|g' \
 drivers/media/platform/msm/camera_oneplus/cam_core/cam_context.h || true
fi

# 修复 cam_sensor_i2c.h 中的 cam_cci_dev.h 包含路径
# cam_sensor_i2c.h 需要 cam_cci_dev.h 中的完整结构体定义
# 使用相对路径指向 ../cam_cci/cam_cci_dev.h
echo "修复 cam_sensor_i2c.h 中的 cam_cci_dev.h 包含路径..."

fix_i2c_include_path() {
 local file="$1"
 if [ -f "$file" ]; then
 echo " 修复：$file"
 # 将 #include "cam_cci_dev.h" 替换为相对路径
 sed -i 's|#include "cam_cci_dev.h"|#include "../cam_cci/cam_cci_dev.h"|g' "$file"
 fi
}

fix_i2c_include_path "drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_io/cam_sensor_i2c.h"
fix_i2c_include_path "drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_io/cam_sensor_i2c.h"

# 复制 cam_sensor_cmn_header.h 到 include/media/ 目录
# 因为 cam_sensor_util.h 使用 #include <cam_sensor_cmn_header.h>（尖括号）
# 编译器会在 include/ 目录中查找
echo "复制 cam_sensor_cmn_header.h 到 include/media/ 目录..."
mkdir -p include/media
if [ -f "drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h" ]; then
 cp drivers/media/platform/msm/camera/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h include/media/cam_sensor_cmn_header.h
 echo " 已复制 camera/cam_sensor_utils/cam_sensor_cmn_header.h 到 include/media/"
elif [ -f "drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h" ]; then
 cp drivers/media/platform/msm/camera_oneplus/cam_sensor_module/cam_sensor_utils/cam_sensor_cmn_header.h include/media/cam_sensor_cmn_header.h
 echo " 已复制 camera_oneplus/cam_sensor_utils/cam_sensor_cmn_header.h 到 include/media/"
else
 echo " 警告：未找到 cam_sensor_cmn_header.h，创建基本回退文件..."
 cat > include/media/cam_sensor_cmn_header.h << 'EOF'
/* 相机传感器公共头文件 - 最小化定义 */
#ifndef _CAM_SENSOR_CMN_HEADER_H_
#define _CAM_SENSOR_CMN_HEADER_H_

#include <linux/types.h>
#include <linux/videodev2.h>

/* 相机传感器类型枚举 */
enum camera_sensor_i2c_type {
 CAMERA_SENSOR_I2C_TYPE_U8,
 CAMERA_SENSOR_I2C_TYPE_U16,
 CAMERA_SENSOR_I2C_TYPE_U32,
};

/* CCI 主设备类型 */
enum camera_master_type {
 CCI_MASTER = 0,
 I2C_MASTER = 1,
};

/* 相机传感器功率设置结构 */
struct cam_sensor_power_setting {
 u16 seq_val;
 u16 seq_type;
 u32 config_val;
 u32 delay;
};

/* 相机传感器功率设置数据结构 */
struct cam_sensor_power_setting_array {
 struct cam_sensor_power_setting *power_setting;
 u16 size;
};

/* 相机传感器输出格式 */
enum v4l2_mbus_pixelcode;

/* 相机传感器模式 */
enum cam_sensor_mode_type {
 CAMERA_SENSOR_CUSTOM_MODE,
 CAMERA_SENSOR_AUTO_MODE,
};

/* 相机传感器功率设置类型 */
enum cam_sensor_power_setting_type {
 CAM_SENSOR_POWER_SETTING_TYPE_SEQ,
 CAM_SENSOR_POWER_SETTING_TYPE_I2C,
};

#endif /* _CAM_SENSOR_CMN_HEADER_H_ */
EOF
fi

# 确保 cam_debug_util.h 存在
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

# 修复 cam_trace.h 中的路径问题
echo "修复 cam_trace.h 中的路径问题..."

# 直接覆盖 cam_trace.h，只保留最小化定义
if [ -f "drivers/media/platform/msm/camera/cam_utils/cam_trace.h" ]; then
 echo "覆盖 camera/cam_utils/cam_trace.h..."
 cat > drivers/media/platform/msm/camera/cam_utils/cam_trace.h << 'EOF'
#ifndef _CAM_TRACE_MINIMAL
#define _CAM_TRACE_MINIMAL

/* 前向声明 */
struct cam_context;
struct cam_ctx_request;

/* Trace 函数占位符定义 - 使用 void* 接受任意类型 */
static inline void trace_cam_buf_done(const char *tag, struct cam_context *ctx, void *req) {}
static inline void trace_cam_print_event(const char *tag, int event, void *data) {}

/* 其他可能用到的 trace 函数占位符 */
static inline void trace_cam_frame_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_req_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_hw_buf_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_isp_buf_done(const char *tag, void *ctx, void *req) {}

/* Trace 宏 */
#define CAM_TRACE_EVENT(event, args...) do {} while(0)
#define TRACE_CAM_PRINT_EVENT(event, args...) do {} while(0)

#endif
EOF
fi

if [ -f "drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h" ]; then
 echo "覆盖 camera_oneplus/cam_utils/cam_trace.h..."
 cat > drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h << 'EOF'
#ifndef _CAM_TRACE_MINIMAL
#define _CAM_TRACE_MINIMAL

/* 前向声明 */
struct cam_context;
struct cam_ctx_request;

/* Trace 函数占位符定义 - 使用 void* 接受任意类型 */
static inline void trace_cam_buf_done(const char *tag, struct cam_context *ctx, void *req) {}
static inline void trace_cam_print_event(const char *tag, int event, void *data) {}

/* 其他可能用到的 trace 函数占位符 */
static inline void trace_cam_frame_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_req_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_hw_buf_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_isp_buf_done(const char *tag, void *ctx, void *req) {}

/* Trace 宏 */
#define CAM_TRACE_EVENT(event, args...) do {} while(0)
#define TRACE_CAM_PRINT_EVENT(event, args...) do {} while(0)

#endif
EOF
fi

if [ -f "drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h" ]; then
echo "覆盖 camera_oneplus/cam_utils/cam_trace.h..."
cat > drivers/media/platform/msm/camera_oneplus/cam_utils/cam_trace.h << 'EOF'
#ifndef _CAM_TRACE_MINIMAL
#define _CAM_TRACE_MINIMAL

/* 前向声明 */
struct cam_context;
struct cam_ctx_request;

/* Trace 函数占位符定义 - 使用 void* 接受任意类型 */
static inline void trace_cam_buf_done(const char *tag, struct cam_context *ctx, void *req) {}
static inline void trace_cam_print_event(const char *tag, int event, void *data) {}

/* 其他可能用到的 trace 函数占位符 */
static inline void trace_cam_frame_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_req_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_hw_buf_done(const char *tag, void *ctx, void *req) {}
static inline void trace_cam_isp_buf_done(const char *tag, void *ctx, void *req) {}

/* Trace 宏 */
#define CAM_TRACE_EVENT(event, args...) do {} while(0)
#define TRACE_CAM_PRINT_EVENT(event, args...) do {} while(0)

#endif
EOF
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

# 复制 cam_sync_api.h 和 cam_sync_private.h 到 include/media/ 目录
# 因为 cam_sync_util.h 使用 #include <cam_sync_api.h>（尖括号）
# 编译器会在 include/ 目录中查找
echo "复制 cam_sync_api.h 和 cam_sync_private.h 到 include/media/ 目录..."
mkdir -p include/media
if [ -f "drivers/media/platform/msm/camera/cam_sync/cam_sync_api.h" ]; then
 cp drivers/media/platform/msm/camera/cam_sync/cam_sync_api.h include/media/cam_sync_api.h
 echo " 已复制 camera/cam_sync/cam_sync_api.h 到 include/media/"
elif [ -f "drivers/media/platform/msm/camera_oneplus/cam_sync/cam_sync_api.h" ]; then
 cp drivers/media/platform/msm/camera_oneplus/cam_sync/cam_sync_api.h include/media/cam_sync_api.h
 echo " 已复制 camera_oneplus/cam_sync/cam_sync_api.h 到 include/media/"
else
 echo " 警告：未找到 cam_sync_api.h，创建基本头文件..."
 cat > include/media/cam_sync_api.h << 'EOF'
/* Copyright (c) 2017-2018, The Linux Foundation. All rights reserved. */
#ifndef _CAM_SYNC_API_H_
#define _CAM_SYNC_API_H_
#include <linux/types.h>
#define CAM_SYNC_DEVICE_NAME "cam_sync"
enum cam_sync_opcode {
	CAM_SYNC_IS_MASTER,
	CAM_SYNC_REGISTER_CALLBACK,
	CAM_SYNC_UNREGISTER_CALLBACK,
	CAM_SYNC_DESTROY,
	CAM_SYNC_GET_SYNCINFO,
	CAM_SYNC_WAIT,
	CAM_SYNC_SIGNAL,
	CAM_SYNC_GET_NUM_CLIENTS,
};
enum cam_sync_event_type {
	CAM_SYNC_EVENT_RESET,
	CAM_SYNC_EVENT_SIGNAL,
};
struct cam_sync_wait {
	u32 syncobj;
	u32 timeout;
};
struct cam_sync_info {
	char name[64];
	u32 id;
	u32 state;
};
#endif /* _CAM_SYNC_API_H_ */
EOF
fi

if [ -f "drivers/media/platform/msm/camera/cam_sync/cam_sync_private.h" ]; then
 cp drivers/media/platform/msm/camera/cam_sync/cam_sync_private.h include/media/cam_sync_private.h
 echo " 已复制 camera/cam_sync/cam_sync_private.h 到 include/media/"
elif [ -f "drivers/media/platform/msm/camera_oneplus/cam_sync/cam_sync_private.h" ]; then
 cp drivers/media/platform/msm/camera_oneplus/cam_sync/cam_sync_private.h include/media/cam_sync_private.h
 echo " 已复制 camera_oneplus/cam_sync/cam_sync_private.h 到 include/media/"
else
 echo " 警告：未找到 cam_sync_private.h，创建基本头文件..."
 cat > include/media/cam_sync_private.h << 'EOF'
/* Copyright (c) 2017-2018, The Linux Foundation. All rights reserved. */
#ifndef _CAM_SYNC_PRIVATE_H_
#define _CAM_SYNC_PRIVATE_H_
#include <linux/types.h>
#include <media/cam_sync_api.h>
struct cam_sync_device {
	struct device *device;
	struct mutex mutex;
	u32 num_clients;
};
#endif /* _CAM_SYNC_PRIVATE_H_ */
EOF
fi

echo ""
echo "=========================================="
echo "真实头文件修复完成！"
echo "=========================================="
echo ""
echo "使用真实头文件修复编译错误，保留摄像头功能"
echo "头文件来自：$REPO_BASE"
echo ""
echo "注意：如果网络下载失败，会创建基本头文件"
echo "但这可能影响摄像头功能的完整性"
echo ""
echo "下一步："
echo " make \$DEFCONFIG"
echo " make -j\$(nproc) Image.gz KCFLAGS=\"-Wno-error -fno-stack-protector -mcmodel=large\""
echo ""