#!/bin/bash
# inject-docker-kernel.sh — 把 Docker 内核(模块 + boot.img)注入 mic 已组装的 rootfs。
#
# 由 kickstart 的 %post --nochroot 钩子调用，运行在 mic 宿主侧(容器内 root 用户)，
# 在 mic 把 rootfs 打成 tar.bz2 之前完成注入，保证刷机包里的 /boot/hybris-boot.img
# 就是 Docker 内核镜像、/lib/modules 含配套内核模块。
#
# 用法:
#   inject-docker-kernel.sh <INSTALL_ROOT> <artifacts-dir> [RELEASE]
#
# artifacts-dir 需包含(由 workflow 从 gmicroul/fajita-sfos-docker-ci release 下载):
#   boot_a-docker-v2.img                       # Docker 内核 boot 镜像
#   docker-kernel-oneplus6t-*.aarch64.rpm      # Docker 内核 rpm(校验用)
#   boot_a-backup-before-docker.img            # 刷机前的 stock boot(用于设备端回滚)
#   payload/                                   # extract-rpm.py 解包出的 rpm 内容

set -euo pipefail

ROOT="${1:?用法: inject-docker-kernel.sh <INSTALL_ROOT> <artifacts-dir> [RELEASE]}"
ART="${2:?缺少 artifacts 目录}"
RELEASE="${3:-5.1.0.11}"   # 仅用于回滚备份文件名标注

# 固定版本常量(与 gmicroul/fajita-sfos-docker-ci release 产物一一对应)
BOOT_SHA="b17c9fbd28529bcb4fe1e8514a74e9dfd991bb28470a3d6b662089f9b202783d"
RPM_SHA="b926aefdf2c60bce02a021b945caa55a9b82b4c6f5adb5a0a305b6590cda93c5"
BACKUP_BOOT_SHA="3cf5250c2831ce268b095c4c6489a483b258f8c1b0fe7609b4599137092a817a"
KREL="4.9.209-hybris-g5eb4c03127-dirty"   # 与 rpm 内 kernelrelease 一致

BOOT_IMG="$ART/boot_a-docker-v2.img"
RPM="$ART/docker-kernel-oneplus6t-4.9.209_docker-1.g5eb4c03127.aarch64.rpm"
BACKUP_IMG="$ART/boot_a-backup-before-docker.img"
PAYLOAD="$ART/payload"

die() { echo "[inject-docker-kernel] 错误: $*" >&2; exit 1; }
info() { echo "[inject-docker-kernel] $*"; }

[ -d "$ROOT" ] || die "INSTALL_ROOT 不存在: $ROOT"
[ -d "$ROOT/boot" ] || mkdir -p "$ROOT/boot"

# ---------- 1. 校验来源产物 sha256 ----------
[ -f "$BOOT_IMG" ] || die "缺少 $BOOT_IMG"
[ -f "$RPM" ] || die "缺少 $RPM"
info "校验产物 sha256 ..."
sha256sum "$BOOT_IMG" | grep -q "^$BOOT_SHA " || die "boot_a-docker-v2.img sha256 不匹配"
sha256sum "$RPM" | grep -q "^$RPM_SHA " || die "docker-kernel rpm sha256 不匹配"
info "boot 镜像 / rpm sha256 校验通过"

# ---------- 2. 注入 rpm payload(模块 + boot.img + 安装脚本) ----------
[ -d "$PAYLOAD" ] || die "缺少解包目录 $PAYLOAD"
[ -d "$PAYLOAD/lib/modules/$KREL" ] || die "payload 缺少 lib/modules/$KREL"
[ -f "$PAYLOAD/lib/modules/$KREL/wlan.ko" ] || die "payload 缺少 wlan.ko"
[ -f "$PAYLOAD/usr/share/docker-kernel-oneplus6t/boot.img" ] || die "payload 缺少包内 boot.img"

info "复制内核模块与脚本到 rootfs ($ROOT) ..."
cp -a "$PAYLOAD/." "$ROOT/"
[ -d "$ROOT/lib/modules/$KREL" ] || die "模块未注入到 $ROOT/lib/modules/$KREL"

# ---------- 3. 用 Docker boot 镜像替换 /boot/hybris-boot.img ----------
# TWRP 安装器会把 rootfs 内 /boot/hybris-boot.img 刷进活动 slot 的 boot 分区，
# 因此刷完 zip 后直接就是 Docker 内核。
if [ -f "$ROOT/boot/hybris-boot.img" ]; then
    info "备份原 hybris-boot.img -> hybris-boot.img.stock"
    cp -f "$ROOT/boot/hybris-boot.img" "$ROOT/boot/hybris-boot.img.stock"
fi
cp -f "$BOOT_IMG" "$ROOT/boot/hybris-boot.img"
sha256sum "$ROOT/boot/hybris-boot.img" | grep -q "^$BOOT_SHA " \
    || die "写入 /boot/hybris-boot.img 后 sha256 校验失败"

# ---------- 4. 预置设备端回滚备份 ----------
# install-docker-kernel 首次刷机会把当前 boot 备份到
# /root/kernel-backups/oneplus6t-docker/；这里直接预置刷机前的 stock boot，
# 让 rollback-docker-kernel 开箱即用。
if [ -f "$BACKUP_IMG" ]; then
    sha256sum "$BACKUP_IMG" | grep -q "^$BACKUP_BOOT_SHA " || die "backup boot img sha256 不匹配"
    BACKUP_DIR="$ROOT/root/kernel-backups/oneplus6t-docker"
    mkdir -p "$BACKUP_DIR"
    cp -f "$BACKUP_IMG" "$BACKUP_DIR/boot_a-before-docker-$RELEASE.img"
    echo "$BACKUP_BOOT_SHA  boot_a-before-docker-$RELEASE.img" \
        > "$BACKUP_DIR/boot_a-before-docker-$RELEASE.img.sha256"
    info "已预置回滚备份: root/kernel-backups/oneplus6t-docker/"
fi

# ---------- 5. 汇总 ----------
info "注入完成:"
info "  - 内核模块: /lib/modules/$KREL"
info "  - boot 镜像: /boot/hybris-boot.img -> docker (sha256 ${BOOT_SHA:0:12}...)"
[ -f "$ROOT/usr/share/docker-kernel-oneplus6t/boot.img" ] \
    && info "  - 包内镜像: /usr/share/docker-kernel-oneplus6t/boot.img"
info "  - 设备端脚本: /usr/sbin/install-docker-kernel, /usr/sbin/rollback-docker-kernel"