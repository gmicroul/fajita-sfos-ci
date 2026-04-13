#!/bin/bash

# 本地Docker内核编译脚本
# 针对一加6T(fajita)设备

set -e

echo "=========================================="
echo "一加6T Docker内核本地编译"
echo "=========================================="
echo ""

# 设置环境变量
export DEVICE="fajita"
export RELEASE="5.0.0.73"
export ANDROID_ROOT="$HOME/android-build"
export GITHUB_WORKSPACE="$(pwd)"

# 创建构建目录
mkdir -p "$ANDROID_ROOT"
cd "$ANDROID_ROOT"

# 步骤1: 清理磁盘空间 (跳过sudo操作)
echo "1. 清理磁盘空间..."
echo "  跳过系统目录清理(需要sudo权限)"

echo "2. 安装编译依赖..."
sudo apt-get update
sudo apt-get install -y \
  git wget curl unzip build-essential ccache python3 python3-pip \
  openjdk-8-jdk rsync bc bison flex lib32ncurses-dev lib32z1-dev \
  libssl-dev libxml2-utils xsltproc zip \
  gcc-12-aarch64-linux-gnu g++-12-aarch64-linux-gnu \
  gcc-12-arm-linux-gnueabihf g++-12-arm-linux-gnueabihf

# 创建交叉编译器符号链接 (跳过sudo操作)
echo "3. 配置交叉编译器..."
echo "  跳过符号链接创建(需要sudo权限)"
echo "  请手动运行以下命令:"
echo "  sudo ln -sf /usr/bin/aarch64-linux-gnu-gcc-12 /usr/bin/aarch64-linux-gnu-gcc"
echo "  sudo ln -sf /usr/bin/aarch64-linux-gnu-g++-12 /usr/bin/aarch64-linux-gnu-g++"

# 步骤2: 克隆内核源码
echo "4. 克隆内核源码..."
if [ -d "kernel/oneplus/sdm845" ]; then
    echo "  内核目录已存在，跳过克隆"
else
    git clone --depth 1 --single-branch --branch lineage-16.0 \
        https://github.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable.git \
        kernel/oneplus/sdm845
fi

# 步骤3: 应用Docker内核补丁
echo "5. 应用Docker内核补丁..."
cd kernel/oneplus/sdm845
bash "$GITHUB_WORKSPACE/scripts/apply-docker-kernel-patch-v2.sh"

# 步骤4: 清理问题驱动
echo "6. 清理问题驱动..."
bash "$GITHUB_WORKSPACE/scripts/clean-kernel-drivers-v2.sh" "$(pwd)"

# 步骤5: 创建空的trace头文件
echo "7. 创建空的trace头文件..."
bash "$GITHUB_WORKSPACE/scripts/create-empty-trace-headers.sh" "$(pwd)"

# 步骤6: 编译内核
echo "8. 编译内核..."
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=aarch64-linux-gnu-gcc
export PATH=/usr/bin:$PATH

# 查找正确的defconfig
if [ -f "arch/arm64/configs/fajita_defconfig" ]; then
    DEFCONFIG="fajita_defconfig"
elif [ -f "arch/arm64/configs/lineage_fajita_defconfig" ]; then
    DEFCONFIG="lineage_fajita_defconfig"
elif [ -f "arch/arm64/configs/sdm845_defconfig" ]; then
    DEFCONFIG="sdm845_defconfig"
else
    echo "错误：未找到合适的defconfig"
    exit 1
fi

echo "使用defconfig: $DEFCONFIG"

# 配置内核
make $DEFCONFIG

# 禁用stack protector
sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/CONFIG_CC_STACKPROTECTOR_STRONG=n/g' .config || true
sed -i 's/CONFIG_CC_STACKPROTECTOR=y/CONFIG_CC_STACKPROTECTOR=n/g' .config || true

# 编译内核
make -j$(nproc) Image.gz KCFLAGS="-Wno-error -fno-stack-protector -Wno-implicit-function-declaration" WERROR=0

# 检查编译结果
if [ ! -f "arch/arm64/boot/Image.gz" ]; then
    echo "错误：内核编译失败"
    exit 1
fi

echo "内核编译成功!"
ls -lh arch/arm64/boot/Image.gz

# 步骤7: 准备boot.img重新打包
echo "9. 准备boot.img重新打包..."
cd "$ANDROID_ROOT"
mkdir -p boot-repack

# 下载LineageOS 16 boot.img
echo "下载LineageOS 16 OTA包..."
wget -O boot-repack/lineage-16.0-fajita.zip \
    https://gh-proxy.com/https://github.com/VerdandiTeam/droid-config-enchilada/releases/download/4.5.0.13/lineage-16.0-20200325-nightly-fajita-signed.zip

# 提取boot.img
echo "提取boot.img..."
git clone https://github.com/vm03/payload_dumper.git
cd payload_dumper
pip3 install -q protobuf bsdiff4 brotli zstandard fsspec
python3 payload_dumper.py ../boot-repack/lineage-16.0-fajita.zip
cp output/boot.img ../boot-repack/
cp output/dtbo.img ../boot-repack/

# 安装boot镜像工具 (跳过sudo操作)
echo "  跳过系统安装(需要sudo权限)"
echo "  请手动安装: sudo apt-get install -y abootimg"
# git clone https://github.com/osm0sis/mkbootimg.git /tmp/mkbootimg
# cd /tmp/mkbootimg
# sed -i 's/-Werror//g' Makefile
# sed -i 's/-Werror//g' libmincrypt/Makefile
# make
# sudo cp mkbootimg /usr/local/bin/
# sudo cp unpackbootimg /usr/local/bin/

# 解包原boot.img
cd "$ANDROID_ROOT/boot-repack"
abootimg -x boot.img bootimg.cfg zImage initrd.img dtb

# 替换内核
cp "$ANDROID_ROOT/kernel/oneplus/sdm845/arch/arm64/boot/Image.gz" zImage

# 重新打包
mkbootimg \
    --kernel zImage \
    --ramdisk initrd.img \
    --cmdline "androidboot.hardware=qcom androidboot.console=ttyMSM0 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 swiotlb=2048 androidboot.configfs=true androidboot.usbcontroller=a600000.dwc3 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 buildvariant=userdebug" \
    --base 0x80000000 \
    --pagesize 4096 \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x01000000 \
    --second_offset 0x00f00000 \
    --tags_offset 0x00000100 \
    -o hybris-boot.img

echo "=========================================="
echo "编译完成!"
echo "=========================================="
echo ""
echo "生成的文件:"
echo "- hybris-boot.img (完整引导镜像)"
echo "- Image.gz (内核镜像)"
echo ""
echo "位置: $ANDROID_ROOT/boot-repack/"
ls -lh hybris-boot.img
