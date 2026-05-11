#!/bin/bash
# run-mic2.sh - 由 GitHub Actions enchilada-ci.yml 调用
# 环境变量由 workflow 传入: VENDOR, DEVICE, PORT_ARCH, RELEASE

sudo mkdir -p /proc/sys/fs/binfmt_misc/
sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc

sudo mic create fs --arch=$PORT_ARCH \
                   --tokenmap=ARCH:$PORT_ARCH,RELEASE:$RELEASE,EXTRA_NAME:"$EXTRA_NAME" \
                   --record-pkgs=name,url \
                   --outdir=sfe-$DEVICE-$RELEASE"$EXTRA_NAME" \
                   --pack-to=sfe-$DEVICE-$RELEASE"$EXTRA_NAME".tar.bz2 \
                   Jolla-@RELEASE@-$DEVICE-@ARCH@.ks