# DisplayName: Jolla fajita-docker/@ARCH@ (release) 5.1.0.11+hybris.16.0 docker-kernel
# KickstartType: release
# DeviceModel: fajita
# DeviceVariant: fajita
# Brand: Jolla
# SuggestedImageType: fs
# SuggestedArchitecture: aarch64
#
# Docker 内核变体 (基于 5.1.0.11):
#   - 在标准 fajita 镜像基础上，注入 docker-kernel-oneplus6t 内核模块
#   - 把 /boot/hybris-boot.img 替换为 Docker 内核 boot 镜像(boot_a-docker-v2.img)
#   - 刷机包刷完即为 Docker 内核，并预置 stock boot 用于 rollback-docker-kernel
#
# 注意: fajita 社区适配包(2026-08 重编译)要求 pulseaudio >= 15.0，
# 5.0.0.67 基础只有 pulseaudio 14.2，故基础版本固定在 5.1.x。

timezone --utc UTC

### Commands from /tmp/sandbox/usr/share/ssu/kickstart/part/default
part / --size 500 --ondisk sda --fstype=ext4

## No suitable configuration found in /tmp/sandbox/usr/share/ssu/kickstart/bootloader

repo --name=adaptation-common-fajita-@RELEASE@ --baseurl=https://releases.jolla.com/releases/@RELEASE@/jolla-hw/adaptation-common/@ARCH@/
# 社区适配源只有 5.1 分支(5.0.0.67 等分支也是同一份新构建)，固定用 sailfishos_5.1
repo --name=adaptation-community-fajita-@RELEASE@ --baseurl=https://repo.sailfishos.org/obs/nemo:/testing:/hw:/oneplus:/fajita/sailfishos_5.1/
repo --name=adaptation-community-common-fajita-@RELEASE@ --baseurl=https://repo.sailfishos.org/obs/nemo:/testing:/hw:/common/sailfishos_5.1_@ARCH@/
repo --name=apps-@RELEASE@ --baseurl=https://releases.jolla.com/jolla-apps/@RELEASE@/@ARCH@/
repo --name=chum-@RELEASE@ --baseurl=https://repo.sailfishos.org/obs/sailfishos:/chum/5.1_@ARCH@/
repo --name=hotfixes-@RELEASE@ --baseurl=https://releases.jolla.com/releases/@RELEASE@/hotfixes/@ARCH@/
repo --name=jolla-@RELEASE@ --baseurl=https://releases.jolla.com/releases/@RELEASE@/jolla/@ARCH@/
repo --name=mister-@RELEASE@ --baseurl=https://sailfish.openrepos.net/Mister_Magister/personal/main
repo --name=storeman-@RELEASE@ --baseurl=https://repo.sailfishos.org/obs/home:/olf:/harbour-storeman/5.1_@ARCH@/

%packages
#-pulseaudio-modules-droid-jb2q
#htop
#-pulseaudio-modules-droid-jb2q-14.2.100-1.2.2.bso.aarch64
patterns-sailfish-device-configuration-fajita
%end

%attachment
### Commands from /tmp/sandbox/usr/share/ssu/kickstart/attachment/fajita
/boot/hybris-boot.img
/boot/hybris-updater-script
/boot/hybris-updater-unpack.sh
/boot/update-binary

%end

%pre --erroronfail
export SSU_RELEASE_TYPE=release
### begin 01_init
touch $INSTALL_ROOT/.bootstrap
### end 01_init
%end

%post --erroronfail
export SSU_RELEASE_TYPE=release
### begin 01_arch-hack
if [ "@ARCH@" == armv7hl ] || [ "@ARCH@" == armv7tnhl ] || [ "@ARCH@" == aarch64 ]; then
    # Without this line the rpm does not get the architecture right.
    echo -n "@ARCH@-meego-linux" > /etc/rpm/platform

    # Also libzypp has problems in autodetecting the architecture so we force tha as well.
    # https://bugs.meego.com/show_bug.cgi?id=11484
    echo "arch = @ARCH@" >> /etc/zypp/zypp.conf
fi
### end 01_arch-hack
### begin 01_rpm-rebuilddb
# Rebuild db using target's rpm
echo -n "Rebuilding db using target rpm.."
rm -f /var/lib/rpm/__db*
rpm --rebuilddb
echo "done"
### end 01_rpm-rebuilddb
### begin 50_oneshot
# exit boostrap mode
rm -f /.bootstrap

# export some important variables until there's a better solution
export LANG=en_US.UTF-8
export LC_COLLATE=en_US.UTF-8

# run the oneshot triggers for root and first user uid
UID_MIN=$(grep "^UID_MIN" /etc/login.defs |  tr -s " " | cut -d " " -f2)
DEVICEUSER=`getent passwd $UID_MIN | sed 's/:.*//'`

if [ -x /usr/bin/oneshot ]; then
   /usr/bin/oneshot --mic
   su -c "/usr/bin/oneshot --mic" $DEVICEUSER
fi
### end 50_oneshot
### begin 60_ssu
if [ "$SSU_RELEASE_TYPE" = "rnd" ]; then
    [ -n "@RELEASE@" ] && ssu release -r @RELEASE@
    [ -n "@FLAVOUR@" ] && ssu flavour @FLAVOUR@
    ssu mode 2
else
    [ -n "@RELEASE@" ] && ssu release @RELEASE@
    ssu mode 4
fi
### end 60_ssu
### begin 70_fix-android-paranoid-network
# Docker 内核(基于 LineageOS defconfig)默认开启 CONFIG_ANDROID_PARANOID_NETWORK，
# 非 root 用户(如 defaultuser, uid 100000)不在 Android 的 AID_INET(3003) 组，
# 会被内核拒绝创建网络套接字 -> 浏览器/curl 全部打不开。
# 治本是重编内核时把该选项设 n(见 scripts/fix-paranoid-network.sh)。
#
# 兜底: 利用 SFOS 原生的 oneshot 机制在**首次开机**时把默认用户加入 gid 3003。
# 为什么不能用构建期 usermod: defaultuser 由 user-managerd 在设备首次开机时
# 才创建(mic 构建期 /etc/passwd 里没有该用户)，构建期 usermod 必然落空。
# SFOS 的 /usr/lib/oneshot.d/groupadd-user.later 会在首次开机扫描
# /etc/oneshot.d/group.d/ 下的组名文件，把主用户(defaultuser)加入对应组
# (镜像内已有先例: group.d/mtp)。这里只需确认 gid 3003 组存在并预置组名文件。
GRP=$(getent group 3003 | cut -d: -f1)
if [ -z "$GRP" ]; then
    echo "[paranoid-network] 警告: gid 3003 不存在，尝试创建 inet 组"
    groupadd -g 3003 inet && GRP=inet
fi
if [ -n "$GRP" ]; then
    mkdir -p /etc/oneshot.d/group.d
    touch "/etc/oneshot.d/group.d/$GRP"
    echo "[paranoid-network] 已预置首次开机加组钩子: /etc/oneshot.d/group.d/$GRP (gid 3003)"
else
    echo "[paranoid-network] 错误: 无法创建 gid 3003 组，缓解未预置"
fi
### end 70_fix-android-paranoid-network
%end

%post --nochroot --erroronfail
export SSU_RELEASE_TYPE=release
### begin 50_os-release
(
CUSTOMERS=$(find $INSTALL_ROOT/usr/share/ssu/features.d -name 'customer-*.ini' \
    |xargs --no-run-if-empty sed -n 's/^name[[:space:]]*=[[:space:]]*//p')

cat $INSTALL_ROOT/etc/os-release
echo "SAILFISH_CUSTOMER=\"${CUSTOMERS//$'\n'/ }\""
) > $IMG_OUT_DIR/os-release
### end 50_os-release
### begin 99_check_shadow
IS_BAD=0

echo "Checking that no user has password set in /etc/shadow."
# This grep prints users that have password set, normally nothing
if grep -vE '^[^:]+:[*!]{1,2}:' $INSTALL_ROOT/etc/shadow
then
    echo "A USER HAS PASSWORD SET! THE IMAGE IS NOT SAFE!"
    IS_BAD=1
fi

# Checking that all users use shadow in passwd,
# if they weren't the check above would be useless
if grep -vE '^[^:]+:x:' $INSTALL_ROOT/etc/passwd
then
    echo "BAD PASSWORD IN /etc/passwd! THE IMAGE IS NOT SAFE!"
    IS_BAD=1
fi

# Fail image build if checks fail
[ $IS_BAD -eq 0 ] && echo "No passwords set, good." || exit 1
### end 99_check_shadow
%end

%post --nochroot --erroronfail
export SSU_RELEASE_TYPE=release
### begin docker-kernel-inject
# 把 Docker 内核(模块 + boot.img)注入已组装的 rootfs。
#
# 注意: mic 的 %post 钩子不继承外部环境变量(只传 tokenmap + INSTALL_ROOT/
# IMG_OUT_DIR)，所以产物目录不能靠 workflow 的 env 传入。这里：
#   1) 优先用 tokenmap 传入的 @DOCKER_ARTIFACTS_DIR@（run-mic-docker.sh 负责）
#   2) 否则回退到固定路径 /workspace/docker-artifacts
# 产物缺失时明确警告并继续（最终由 workflow 的 zip 校验兜底拦截）。
INJECT_SCRIPT="/workspace/scripts/inject-docker-kernel.sh"
DOCKER_ARTIFACTS_DIR="@DOCKER_ARTIFACTS_DIR@"
case "$DOCKER_ARTIFACTS_DIR" in
    @*@|"") DOCKER_ARTIFACTS_DIR="/workspace/docker-artifacts" ;;
esac
if [ -d "$DOCKER_ARTIFACTS_DIR" ]; then
    echo "[docker-kernel] 检测到产物目录 $DOCKER_ARTIFACTS_DIR，开始注入 Docker 内核..."
    bash "$INJECT_SCRIPT" "$INSTALL_ROOT" "$DOCKER_ARTIFACTS_DIR" "@RELEASE@"
else
    echo "[docker-kernel] 警告: 未找到产物目录 $DOCKER_ARTIFACTS_DIR，跳过注入（刷机包将不带 Docker 内核！）"
fi
### end docker-kernel-inject
%end

%pack --erroronfail
export SSU_RELEASE_TYPE=release
### begin hybris
pushd $IMG_OUT_DIR # ./sfe-$DEVICE-$RELEASE_ID

DEVICE=fajita
EXTRA_NAME=@EXTRA_NAME@
DATE=$(date +"%Y%m%d") # 20191101

# Source release info e.g. VERSION
source ./os-release

# Locate rootfs .tar.bz2 archive
for filename in *.tar.bz2; do
	GEN_IMG_BASE=$(basename $filename .tar.bz2) # sfe-$DEVICE-3.2.0.12
done
if [ ! -e "$GEN_IMG_BASE.tar.bz2" ]; then
	echo "[hybris-installer] No rootfs archive found, exiting..."
	exit 1
fi

# Make sure we have 'bc' to estimate rootfs size
zypper --non-interactive in bc &> /dev/null

# Roughly estimate the final rootfs size when installed
IMAGE_SIZE=`echo "scale=2; 2.25 * $(du -h $GEN_IMG_BASE.tar.bz2 | cut -d'M' -f1)" | bc`
echo "[hybris-installer] Estimated rootfs size when installed: ${IMAGE_SIZE}M"

# Output filenames
DST_IMG=sfos-rootfs.tar.bz2
DST_PKG=$ID-$VERSION_ID-$DATE-$DEVICE$EXTRA_NAME-SLOT_a # sailfishos-3.2.0.12-20191101-$DEVICE

# Clone hybris-installer if not preset (e.g. porters-ci build env)
if [ ! -d ../hybris/hybris-installer/ ]; then
	git clone --depth 1 https://github.com/sailfish-oneplus6/hybris-installer ../hybris/hybris-installer > /dev/null
fi

# Copy rootfs & hybris-installer scripts into updater .zip tree
mkdir updater/
mv $GEN_IMG_BASE.tar.bz2 updater/$DST_IMG
cp -r ../hybris/hybris-installer/hybris-installer/* updater/

# Update install script with image details
LOS_VER="16.0"
sed -e "s/%DEVICE%/$DEVICE/g" -e "s/%VERSION%/$VERSION/g" -e "s/%DATE%/$DATE/g" -e "s/%IMAGE_SIZE%/${IMAGE_SIZE}M/g" -e "s/%DST_PKG%/$DST_PKG/g" -e "s/%LOS_VER%/$LOS_VER/g" -i updater/META-INF/com/google/android/update-binary

# Pack updater .zip
pushd updater # sfe-$DEVICE-$RELEASE_ID/updater
echo "[hybris-installer] Creating package '$DST_PKG.zip'..."
zip -r ../$DST_PKG.zip .
mv $DST_IMG ../$GEN_IMG_BASE.tar.bz2
popd # sfe-$DEVICE-$RELEASE_ID

# Clean up working directory
rm -rf updater/

# Calculate some checksums for the generated zip
printf "[hybris-installer] Calculating MD5, SHA1 & SHA256 checksums for '$DST_PKG.zip'..."
md5sum $DST_PKG.zip > $DST_PKG.zip.md5sum
sha1sum $DST_PKG.zip > $DST_PKG.zip.sha1sum
sha256sum $DST_PKG.zip > $DST_PKG.zip.sha256sum
echo " DONE!"

popd # hadk source tree
### end hybris
%end