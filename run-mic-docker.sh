#!/bin/bash
# run-mic-docker.sh - 构建 SailfishOS 5.0.0.67 fajita Docker 刷机包
# 由 GitHub Actions fajita-docker-ci.yml 调用，环境变量由 workflow 传入:
#   VENDOR, DEVICE, PORT_ARCH, RELEASE, DOCKER_ARTIFACTS_DIR
#
# 与 run-mic1.sh 的区别:
#   1. 使用 Jolla-@RELEASE@-fajita-docker-@ARCH@.ks(Docker 内核变体)
#   2. sudo -E 保留 DOCKER_ARTIFACTS_DIR 等环境变量，让 ks 的
#      %post --nochroot 钩子能定位注入脚本与产物

set -e

sudo mkdir -p /proc/sys/fs/binfmt_misc/
sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc || true

sudo -E mic create fs --arch=$PORT_ARCH \
                   --tokenmap=ARCH:$PORT_ARCH,RELEASE:$RELEASE,EXTRA_NAME:"$EXTRA_NAME" \
                   --record-pkgs=name,url \
                   --outdir=sfe-$DEVICE-$RELEASE \
                   --pack-to=sfe-$DEVICE-$RELEASE.tar.bz2 \
                   Jolla-@RELEASE@-$DEVICE-docker-@ARCH@.ks