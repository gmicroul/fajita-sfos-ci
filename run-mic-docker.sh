#!/bin/bash
# run-mic-docker.sh - 构建 SailfishOS 5.1.0.11 fajita Docker 刷机包
# 由 GitHub Actions fajita-docker-ci.yml 调用，环境变量由 workflow 传入:
#   VENDOR, DEVICE, PORT_ARCH, RELEASE, DOCKER_ARTIFACTS_DIR
#
# 与 run-mic1.sh 的区别:
#   1. 使用 Jolla-@RELEASE@-fajita-docker-@ARCH@.ks(Docker 内核变体)
#   2. 把 DOCKER_ARTIFACTS_DIR 通过 mic --tokenmap 传给 ks 的 %post 钩子
#      （mic 的 %post 钩子不继承外部环境变量，tokenmap 是唯一官方通道）
#   3. 构建前预检 docker 产物是否就位，缺失直接失败而非静默出包

set -e

ARTIFACTS="${DOCKER_ARTIFACTS_DIR:-/workspace/docker-artifacts}"

# ---------- 预检: docker 内核产物必须就位 ----------
if [ ! -f "$ARTIFACTS/boot_a-docker-v2.img" ] || [ ! -d "$ARTIFACTS/payload" ]; then
    echo "[run-mic-docker] 错误: docker 内核产物不完整，目录: $ARTIFACTS" >&2
    echo "[run-mic-docker] 请检查 workflow 的 'Copy files into Docker container' 步骤" >&2
    exit 1
fi
echo "[run-mic-docker] 产物目录 OK: $ARTIFACTS"

# ---------- mic 构建 ----------
sudo mkdir -p /proc/sys/fs/binfmt_misc/
sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true

sudo -E mic create fs --arch=$PORT_ARCH \
                   --tokenmap=ARCH:$PORT_ARCH,RELEASE:$RELEASE,EXTRA_NAME:"$EXTRA_NAME",DOCKER_ARTIFACTS_DIR:$ARTIFACTS \
                   --record-pkgs=name,url \
                   --outdir=sfe-$DEVICE-$RELEASE \
                   --pack-to=sfe-$DEVICE-$RELEASE.tar.bz2 \
                   Jolla-@RELEASE@-$DEVICE-docker-@ARCH@.ks