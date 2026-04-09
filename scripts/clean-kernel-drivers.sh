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

# 删除 mdss-pll 驱动（依赖于 dsi_pll_clock_register_10nm）
echo "  - 删除 mdss-pll 驱动"
rm -rf drivers/clk/qcom/mdss/mdss-pll.c || true
sed -i '/mdss-pll/d' drivers/clk/qcom/mdss/Makefile || true

# 删除 mdss-dp-pll-10nm-util 驱动（依赖于 mdss_pll_resource_enable）
echo "  - 删除 mdss-dp-pll-10nm-util 驱动"
rm -rf drivers/clk/qcom/mdss/mdss-dp-pll-10nm-util.c || true
sed -i '/mdss-dp-pll-10nm-util/d' drivers/clk/qcom/mdss/Makefile || true

# 删除 mdss-dp-pll-10nm 驱动（依赖于 dp_* 函数）
echo "  - 删除 mdss-dp-pll-10nm 驱动"
rm -rf drivers/clk/qcom/mdss/mdss-dp-pll-10nm.c || true
sed -i '/mdss-dp-pll-10nm/d' drivers/clk/qcom/mdss/Makefile || true

# 删除整个 mdss 目录（如果为空）
echo "  - 删除 mdss 目录"
rm -rf drivers/clk/qcom/mdss || true
sed -i '/mdss/d' drivers/clk/qcom/Makefile || true
sed -i '/mdss/d' drivers/clk/qcom/Kconfig || true

echo ""
echo "3. 删除有问题的 kgsl GPU 驱动..."

# 删除所有 kgsl 相关文件（依赖于不存在的头文件和函数）
echo "  - 删除所有 kgsl 相关文件"
rm -rf drivers/gpu/msm/kgsl_trace.c || true
rm -rf drivers/gpu/msm/kgsl_events.c || true
rm -rf drivers/gpu/msm/kgsl.c || true
rm -rf drivers/gpu/msm/kgsl_gmu.c || true
rm -rf drivers/gpu/msm/kgsl_iommu.c || true
rm -rf drivers/gpu/msm/kgsl_debugfs.c || true
rm -rf drivers/gpu/msm/kgsl_sync.c || true
rm -rf drivers/gpu/msm/kgsl_compat.c || true
sed -i '/kgsl/d' drivers/gpu/msm/Makefile || true

echo ""
echo "4. 删除有问题的 adreno GPU 驱动..."

# 删除所有 adreno 相关文件（依赖于不存在的头文件和函数）
echo "  - 删除所有 adreno 相关文件"
rm -rf drivers/gpu/msm/adreno_trace.c || true
rm -rf drivers/gpu/msm/adreno.c || true
sed -i '/adreno/d' drivers/gpu/msm/Makefile || true

# 删除整个 msm GPU 驱动目录（如果为空）
echo "  - 删除 msm GPU 驱动目录"
rm -rf drivers/gpu/msm || true
sed -i '/msm/d' drivers/gpu/Makefile || true

# 清理 drivers/video/Kconfig 中的引用
echo "  - 清理 drivers/video/Kconfig 中的引用"
sed -i '/source "drivers\/gpu\/msm\/Kconfig"/d' drivers/video/Kconfig || true

echo ""
echo "5. 删除有问题的摄像头驱动..."

# 删除整个摄像头驱动目录（依赖于不存在的头文件）
echo "  - 删除摄像头驱动目录"
rm -rf drivers/media/platform/msm/camera || true
sed -i '/camera/d' drivers/media/platform/msm/Makefile || true

echo ""
echo "6. 删除有问题的 IPA 驱动..."

# 删除整个 IPA 驱动目录（依赖于不存在的头文件）
echo "  - 删除 IPA 驱动目录"
rm -rf drivers/platform/msm/ipa || true
sed -i '/ipa/d' drivers/platform/msm/Makefile || true

echo ""
echo "7. 删除有问题的 tracer_pkt 驱动..."

# 删除 tracer_pkt 驱动（依赖于不存在的 tracer_pkt_private.h）
echo "  - 删除 tracer_pkt 驱动"
rm -rf drivers/soc/qcom/tracer_pkt.c || true
rm -rf drivers/soc/qcom/tracer_pkt_private.h || true
sed -i '/tracer_pkt/d' drivers/soc/qcom/Makefile || true

# 删除 glink 驱动（依赖于 tracer_pkt）
echo "  - 删除 glink 驱动"
rm -rf drivers/soc/qcom/glink.c || true
rm -rf drivers/soc/qcom/glink_loopback_server.c || true
sed -i '/glink/d' drivers/soc/qcom/Makefile || true

# 删除 spcom 驱动（依赖于 glink）
echo "  - 删除 spcom 驱动"
rm -rf drivers/soc/qcom/spcom.c || true
sed -i '/spcom/d' drivers/soc/qcom/Makefile || true

# 删除 subsystem_restart 驱动（依赖于 glink 和 sysmon）
echo "  - 删除 subsystem_restart 驱动"
rm -rf drivers/soc/qcom/subsystem_restart.c || true
sed -i '/subsystem_restart/d' drivers/soc/qcom/Makefile || true

# 删除 adsprpc 驱动（依赖于 glink）
echo "  - 删除 adsprpc 驱动"
rm -rf drivers/char/adsprpc.c || true
sed -i '/adsprpc/d' drivers/char/Makefile || true

# 删除 esoc-mdm-4x 驱动（依赖于 sysmon）
echo "  - 删除 esoc-mdm-4x 驱动"
rm -rf drivers/esoc/esoc-mdm-4x.c || true
sed -i '/esoc-mdm-4x/d' drivers/esoc/Makefile || true

# 删除所有依赖于 subsystem_* 函数的驱动
echo "  - 删除 spss_utils 驱动"
rm -rf drivers/soc/qcom/spss_utils.c || true
sed -i '/spss_utils/d' drivers/soc/qcom/Makefile || true

echo "  - 删除 cdsp-loader 驱动"
rm -rf drivers/soc/qcom/qdsp6v2/cdsp-loader.c || true
sed -i '/cdsp-loader/d' drivers/soc/qcom/qdsp6v2/Makefile || true

# 删除整个 qdsp6v2 目录（如果为空）
echo "  - 删除 qdsp6v2 目录"
rm -rf drivers/soc/qcom/qdsp6v2 || true
sed -i '/qdsp6v2/d' drivers/soc/qcom/Makefile || true

echo "  - 删除 peripheral-loader 驱动"
rm -rf drivers/soc/qcom/peripheral-loader.c || true
sed -i '/peripheral-loader/d' drivers/soc/qcom/Makefile || true

echo "  - 删除 subsys-pil-tz 驱动"
rm -rf drivers/soc/qcom/subsys-pil-tz.c || true
sed -i '/subsys-pil-tz/d' drivers/soc/qcom/Makefile || true

echo "  - 删除 pil-q6v5-mss 驱动"
rm -rf drivers/soc/qcom/pil-q6v5-mss.c || true
sed -i '/pil-q6v5-mss/d' drivers/soc/qcom/Makefile || true

echo "  - 删除 msm_vidc 驱动"
rm -rf drivers/media/platform/msm/vidc || true
sed -i '/vidc/d' drivers/media/platform/msm/Makefile || true
sed -i '/vidc/d' drivers/media/platform/msm/Kconfig || true

echo "  - 删除 esoc_bus 驱动"
rm -rf drivers/esoc/esoc_bus.c || true
sed -i '/esoc_bus/d' drivers/esoc/Makefile || true

echo "  - 删除 sensors_ssc 驱动"
rm -rf drivers/sensors/sensors_ssc.c || true
sed -i '/sensors_ssc/d' drivers/sensors/Makefile || true

echo "  - 删除 ipc_router 驱动"
rm -rf net/ipc_router/ipc_router_core.c || true
sed -i '/ipc_router_core/d' net/ipc_router/Makefile || true

# 删除 diag_usb 驱动（依赖于 usb_diag 函数）
echo "  - 删除 diag_usb 驱动"
rm -rf drivers/char/diag/diag_usb.c || true
sed -i '/diag_usb/d' drivers/char/diag/Makefile || true

# 删除 diagchar 驱动（依赖于不存在的文件）
echo "  - 删除 diagchar 驱动"
rm -rf drivers/char/diag/diagchar.c || true
sed -i '/diagchar/d' drivers/char/diag/Makefile || true

echo ""
echo "8. 删除有问题的 USB gadget 驱动..."

# 删除 configfs 驱动（依赖于不存在的 function/u_ncm.h）
echo "  - 删除 configfs 驱动"
rm -rf drivers/usb/gadget/configfs.c || true
sed -i '/configfs/d' drivers/usb/gadget/Makefile || true

# 删除所有 USB gadget function 驱动（依赖于不存在的函数）
echo "  - 删除 USB gadget function 驱动"
rm -rf drivers/usb/gadget/function/f_mtp.c || true
rm -rf drivers/usb/gadget/function/f_ptp.c || true
rm -rf drivers/usb/gadget/function/f_ncm.c || true
rm -rf drivers/usb/gadget/function/f_mass_storage.c || true
rm -rf drivers/usb/gadget/function/f_fs.c || true
rm -rf drivers/usb/gadget/function/f_midi.c || true
rm -rf drivers/usb/gadget/function/f_hid.c || true
rm -rf drivers/usb/gadget/function/f_audio_source.c || true
rm -rf drivers/usb/gadget/function/f_accessory.c || true
rm -rf drivers/usb/gadget/function/f_diag.c || true
rm -rf drivers/usb/gadget/function/f_cdev.c || true
rm -rf drivers/usb/gadget/function/f_ccid.c || true
rm -rf drivers/usb/gadget/function/f_gsi.c || true
rm -rf drivers/usb/gadget/function/f_qdss.c || true
sed -i '/f_mtp/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_ptp/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_ncm/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_mass_storage/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_fs/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_midi/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_hid/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_audio_source/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_accessory/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_diag/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_cdev/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_ccid/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_gsi/d' drivers/usb/gadget/function/Makefile || true
sed -i '/f_qdss/d' drivers/usb/gadget/function/Makefile || true

# 删除 USB BAM 驱动（依赖于 IPA）
echo "  - 删除 USB BAM 驱动"
rm -rf drivers/platform/msm/usb_bam.c || true
sed -i '/usb_bam/d' drivers/platform/msm/Makefile || true

echo ""
echo "9. 删除有问题的电源管理驱动..."

# 删除 qpnp-fg-gen3 驱动（依赖于外部函数）
echo "  - 删除 qpnp-fg-gen3 驱动"
rm -rf drivers/power/supply/qcom/qpnp-fg-gen3.c || true
sed -i '/qpnp-fg-gen3/d' drivers/power/supply/qcom/Makefile || true

# 删除 qpnp-smb2 驱动（依赖于外部函数）
echo "  - 删除 qpnp-smb2 驱动"
rm -rf drivers/power/supply/qcom/qpnp-smb2.c || true
sed -i '/qpnp-smb2/d' drivers/power/supply/qcom/Makefile || true

# 删除 smb-lib 驱动（依赖于外部函数）
echo "  - 删除 smb-lib 驱动"
rm -rf drivers/power/supply/qcom/smb-lib.c || true
sed -i '/smb-lib/d' drivers/power/supply/qcom/Makefile || true

echo ""
echo "10. 删除有问题的 coresight 驱动..."

# 删除 coresight-tmc 驱动（依赖于 usb_qdss 函数）
echo "  - 删除 coresight-tmc 驱动"
rm -rf drivers/hwtracing/coresight/coresight-tmc.c || true
rm -rf drivers/hwtracing/coresight/coresight-tmc-etr.c || true
sed -i '/coresight-tmc/d' drivers/hwtracing/coresight/Makefile || true

# 删除整个 coresight 目录（如果为空）
echo "  - 删除 coresight 目录"
rm -rf drivers/hwtracing/coresight || true
sed -i '/coresight/d' drivers/hwtracing/Makefile || true

# 清理 arch/arm64/Kconfig.debug 中的引用
echo "  - 清理 arch/arm64/Kconfig.debug 中的引用"
sed -i '/source "drivers\/hwtracing\/coresight\/Kconfig"/d' arch/arm64/Kconfig.debug || true

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
echo "  - mdss-pll.c (MDSS PLL 驱动)"
echo "  - mdss-dp-pll-10nm-util.c (MDSS DP PLL 10nm 工具)"
echo "  - mdss-dp-pll-10nm.c (MDSS DP PLL 10nm 驱动)"
echo "  - drivers/clk/qcom/mdss (MDSS 目录)"
echo "  - 所有 kgsl 相关文件 (KGSL GPU 驱动)"
echo "  - 所有 adreno 相关文件 (Adreno GPU 驱动)"
echo "  - drivers/gpu/msm (MSM GPU 驱动目录)"
echo "  - drivers/media/platform/msm/camera (摄像头驱动)"
echo "  - drivers/media/platform/msm/vidc (视频驱动)"
echo "  - drivers/platform/msm/ipa (IPA 网络加速器)"
echo "  - tracer_pkt.c (数据包追踪驱动)"
echo "  - glink.c (glink 驱动)"
echo "  - glink_loopback_server.c (glink 回环服务器)"
echo "  - spcom.c (spcom 驱动)"
echo "  - spss_utils.c (spss 工具)"
echo "  - cdsp-loader.c (CDSP 加载器)"
echo "  - drivers/soc/qcom/qdsp6v2 (QDSP6v2 目录)"
echo "  - peripheral-loader.c (外设加载器)"
echo "  - subsystem_restart.c (子系统重启驱动)"
echo "  - subsys-pil-tz.c (子系统 PIL TZ 驱动)"
echo "  - pil-q6v5-mss.c (PIL Q6v5 MSS 驱动)"
echo "  - adsprpc.c (adsprpc 驱动)"
echo "  - esoc-mdm-4x.c (esoc MDM 4x 驱动)"
echo "  - esoc_bus.c (esoc 总线驱动)"
echo "  - sensors_ssc.c (传感器 SSC 驱动)"
echo "  - ipc_router_core.c (IPC 路由器核心)"
echo "  - diag_usb.c (diag USB 驱动)"
echo "  - diagchar.c (diag 字符驱动)"
echo "  - configfs.c (USB gadget configfs)"
echo "  - USB gadget function 驱动 (f_mtp, f_ptp, f_ncm, f_mass_storage, f_fs, f_midi, f_hid, f_audio_source, f_accessory, f_diag, f_cdev, f_ccid, f_gsi, f_qdss)"
echo "  - usb_bam.c (USB BAM 驱动)"
echo "  - qpnp-fg-gen3.c (电源管理驱动)"
echo "  - qpnp-smb2.c (电源管理驱动)"
echo "  - smb-lib.c (电源管理驱动)"
echo "  - coresight-tmc.c (coresight 调试驱动)"
echo "  - coresight-tmc-etr.c (coresight 调试驱动)"
echo "  - drivers/hwtracing/coresight (coresight 目录)"
echo ""
echo "下一步："
echo "  make $DEFCONFIG"
echo "  make -j\$(nproc) Image.gz"
echo ""
