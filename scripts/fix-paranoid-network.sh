#!/bin/bash
# fix-paranoid-network.sh — 关闭内核的 CONFIG_ANDROID_PARANOID_NETWORK（治本）。
#
# 背景: docker 内核从 LineageOS 的 defconfig 编译时带上了
#   CONFIG_ANDROID_PARANOID_NETWORK=y —— 该选项只允许 root(或 Android
#   AID_INET=3003/AID_NET_RAW=3004 组成员)创建网络套接字，导致 SFOS 的
#   defaultuser(uid 100000)无法上网(浏览器/curl 全部 Permission denied)。
#   原版 SFOS 内核该选项为 n，因此不存在此问题。
#
# 用法:
#   fix-paranoid-network.sh <kernel-source-dir>
#   fix-paranoid-network.sh        # 使用 $ANDROID_ROOT (默认 /srv/hadk)
#
# 修复后需重新编译内核 -> 重新打包 boot.img / 内核 rpm，再重新构建刷机包。
# 同时可保留 ks 里的 gid 3003 兜底(usermod)，两者不冲突。

set -euo pipefail

KERNEL_DIR="${1:-${ANDROID_ROOT:-/srv/hadk}}"

die() { echo "[fix-paranoid-network] 错误: $*" >&2; exit 1; }
info() { echo "[fix-paranoid-network] $*"; }

[ -d "$KERNEL_DIR" ] || die "内核目录不存在: $KERNEL_DIR"

# 定位 defconfig（与 apply-docker-kernel-patch-v2.sh 的查找逻辑一致）
CONFIG_FILE=""
for cfg in fajita_defconfig lineage_fajita_defconfig sdm845_defconfig; do
    if [ -f "$KERNEL_DIR/arch/arm64/configs/$cfg" ]; then
        CONFIG_FILE="$KERNEL_DIR/arch/arm64/configs/$cfg"
        break
    fi
done
[ -n "$CONFIG_FILE" ] || die "在 $KERNEL_DIR/arch/arm64/configs/ 下未找到 defconfig"

info "操作文件: $CONFIG_FILE"
cp -f "$CONFIG_FILE" "$CONFIG_FILE.bak" 2>/dev/null || true

if grep -qE "^CONFIG_ANDROID_PARANOID_NETWORK=" "$CONFIG_FILE"; then
    old=$(grep -E "^CONFIG_ANDROID_PARANOID_NETWORK=" "$CONFIG_FILE")
    sed -i "s/^CONFIG_ANDROID_PARANOID_NETWORK=.*/CONFIG_ANDROID_PARANOID_NETWORK=n/" "$CONFIG_FILE"
    info "已修改: $old -> CONFIG_ANDROID_PARANOID_NETWORK=n"
else
    echo "CONFIG_ANDROID_PARANOID_NETWORK=n" >> "$CONFIG_FILE"
    info "已追加: CONFIG_ANDROID_PARANOID_NETWORK=n"
fi

info "当前值: $(grep -E '^CONFIG_ANDROID_PARANOID_NETWORK=' "$CONFIG_FILE")"
echo ""
echo "下一步:"
echo "  1. 用该 defconfig 重新编译内核"
echo "  2. 重新生成 boot.img 与内核模块, 重打 docker-kernel-oneplus6t rpm"
echo "  3. 用新 boot.img/rpm 重新构建刷机包(workflow 重新跑一次即可)"
echo ""
echo "验证: 新内核启动后, 非 root 用户(如 defaultuser)执行下面命令应能连上:"
echo "  timeout 3 bash -c 'echo > /dev/tcp/52.30.226.232/80' && echo OK"
echo "  zcat /proc/config.gz | grep PARANOID   # 应显示 =n"