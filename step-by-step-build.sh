#!/bin/bash

# 分步Docker内核编译脚本
# 便于调试和优化

set -e

echo "=========================================="
echo "一加6T Docker内核分步编译"
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

echo "环境变量设置完成:"
echo "  DEVICE=$DEVICE"
echo "  RELEASE=$RELEASE"
echo "  ANDROID_ROOT=$ANDROID_ROOT"
echo ""

# 显示菜单选项
echo "请选择要执行的步骤:"
echo "1. 检查编译环境"
echo "2. 克隆内核源码"
echo "3. 应用Docker内核补丁"
echo "4. 清理问题驱动"
echo "5. 创建空的trace头文件"
echo "6. 编译内核"
echo "7. 下载LineageOS boot.img"
echo "8. 重新打包hybris-boot.img"
echo "9. 完整编译流程"
echo ""

read -p "请输入选项 (1-9): " choice

case $choice in
    1)
        echo "=== 步骤1: 检查编译环境 ==="
        echo "检查基本工具..."
        which git wget curl unzip build-essential ccache python3 python3-pip openjdk-8-jdk rsync bc bison flex lib32ncurses-dev lib32z1-dev libssl-dev libxml2-utils xsltproc zip
        echo "检查交叉编译工具..."
        which aarch64-linux-gnu-gcc aarch64-linux-gnu-g++ arm-linux-gnueabihf-gcc arm-linux-gnueabihf-g++
        echo "环境检查完成"
        ;;
    2)
        echo "=== 步骤2: 克隆内核源码 ==="
        if [ -d "kernel/oneplus/sdm845" ]; then
            echo "内核目录已存在，跳过克隆"
        else
            echo "克隆内核源码..."
            git clone --depth 1 --single-branch --branch lineage-16.0 \\
                https://github.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable.git \\
                kernel/oneplus/sdm845
        fi
        echo "内核源码准备完成"
        ;;
    3)
        echo "=== 步骤3: 应用Docker内核补丁 ==="
        if [ ! -d "kernel/oneplus/sdm845" ]; then
            echo "错误：内核目录不存在，请先执行步骤2"
            exit 1
        fi
        cd kernel/oneplus/sdm845
        bash "$GITHUB_WORKSPACE/scripts/apply-docker-kernel-patch-v2.sh"
        echo "Docker内核补丁应用完成"
        ;;
    4)
        echo "=== 步骤4: 清理问题驱动 ==="
        if [ ! -d "kernel/oneplus/sdm845" ]; then
            echo "错误：内核目录不存在"
            exit 1
        fi
        cd kernel/oneplus/sdm845
        bash "$GITHUB_WORKSPACE/scripts/clean-kernel-drivers-v2.sh" "$(pwd)"
        echo "问题驱动清理完成"
        ;;
    5)
        echo "=== 步骤5: 创建空的trace头文件 ==="
        if [ ! -d "kernel/oneplus/sdm845" ]; then
            echo "错误：内核目录不存在"
            exit 1
        fi
        cd kernel/oneplus/sdm845
        bash "$GITHUB_WORKSPACE/scripts/create-empty-trace-headers.sh" "$(pwd)"
        echo "空的trace头文件创建完成"
        ;;
    6)
        echo "=== 步骤6: 编译内核 ==="
        if [ ! -d "kernel/oneplus/sdm845" ]; then
            echo "错误：内核目录不存在"
            exit 1
        fi
        cd kernel/oneplus/sdm845
        
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
        echo "开始编译内核..."
        make -j$(nproc) Image.gz KCFLAGS="-Wno-error -fno-stack-protector -Wno-implicit-function-declaration" WERROR=0
        
        # 检查编译结果
        if [ ! -f "arch/arm64/boot/Image.gz" ]; then
            echo "错误：内核编译失败"
            exit 1
        fi
        
        echo "内核编译成功!"
        ls -lh arch/arm64/boot/Image.gz
        ;;
    7)
        echo "=== 步骤7: 下载LineageOS boot.img ==="
        cd "$ANDROID_ROOT"
        mkdir -p boot-repack
        
        echo "下载LineageOS 16 OTA包..."
        wget -O boot-repack/lineage-16.0-fajita.zip \\
            https://gh-proxy.com/https://github.com/VerdandiTeam/droid-config-enchilada/releases/download/4.5.0.13/lineage-16.0-20200325-nightly-fajita-signed.zip
        
        echo "提取boot.img..."
        git clone https://github.com/vm03/payload_dumper.git
        cd payload_dumper
        pip3 install -q protobuf bsdiff4 brotli zstandard fsspec
        python3 payload_dumper.py ../boot-repack/lineage-16.0-fajita.zip
        cp output/boot.img ../boot-repack/
        cp output/dtbo.img ../boot-repack/
        
        echo "boot.img下载完成"
        ;;
    8)
        echo "=== 步骤8: 重新打包hybris-boot.img ==="
        echo "注意：此步骤需要sudo权限"
        echo "请手动执行以下命令:"
        echo ""
        echo "# 安装abootimg"
        echo "sudo apt-get install -y abootimg"
        echo ""
        echo "# 解包原boot.img"
        echo "cd $ANDROID_ROOT/boot-repack"
        echo "abootimg -x boot.img bootimg.cfg zImage initrd.img dtb"
        echo ""
        echo "# 替换内核"
        echo "cp $ANDROID_ROOT/kernel/oneplus/sdm845/arch/arm64/boot/Image.gz zImage"
        echo ""
        echo "# 重新打包"
        echo "mkbootimg \\\"
        echo "    --kernel zImage \\\"
        echo "    --ramdisk initrd.img \\\"
        echo "    --cmdline \"androidboot.hardware=qcom androidboot.console=ttyMSM0 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 swiotlb=2048 androidboot.configfs=true androidboot.usbcontroller=a600000.dwc3 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 buildvariant=userdebug\" \\\"
        echo "    --base 0x80000000 \\\"
        echo "    --pagesize 4096 \\\"
        echo "    --kernel_offset 0x00008000 \\\"
        echo "    --ramdisk_offset 0x01000000 \\\"
        echo "    --second_offset 0x00f00000 \\\"
        echo "    --tags_offset 0x00000100 \\\"
        echo "    -o hybris-boot.img"
        ;;
    9)
        echo "=== 完整编译流程 ==="
        echo "执行步骤2-7..."
        $0 2
        $0 3
        $0 4
        $0 5
        $0 6
        $0 7
        echo ""
        echo "步骤8需要手动执行(需要sudo权限)"
        echo "请参考上一步的输出"
        ;;
    *)
        echo "无效选项"
        exit 1
        ;;
esac

echo ""
echo "步骤完成!"