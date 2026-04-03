# Docker 内核支持实现方案 - fajita-sfos-ci

## 问题分析

用户说得对：**安装 docker 包只是用户空间，内核支持才是关键。**

Docker 需要内核级别的支持才能运行，包括：
- Namespaces（命名空间）
- Cgroups（控制组）
- OverlayFS（存储驱动）
- 网络功能（VETH、Bridge、Netfilter）
- 安全功能（Seccomp、AppArmor）

## 当前项目架构

### 内核来源
- **内核镜像**：`/boot/hybris-boot.img`（从 Android 构建中获取）
- **内核源码**：在 `$ANDROID_ROOT/kernel/oneplus/sdm845/`（Android 源码树中）
- **内核配置**：`arch/arm64/configs/fajita_defconfig` 或 `lineageos_fajita_defconfig`

### 关键发现
从 `build-rpm.sh` 中发现：
```bash
sed -i '/CONFIG_NETFILTER_XT_MATCH_QTAGUID/d' hybris/mer-kernel-check/mer_verify_kernel_config
```

这说明：
1. 项目已经修改过内核配置检查
2. 有一个内核配置验证脚本：`hybris/mer-kernel-check/mer_verify_kernel_config`
3. 可以通过修改这个脚本来调整内核配置要求

## Docker 内核要求

### 必需的内核选项

#### 1. Namespaces（命名空间）
```
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
CONFIG_USER_NS=y
```

#### 2. Cgroups（控制组）
```
CONFIG_CGROUPS=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CPUSETS=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_MEMCG=y
CONFIG_BLK_CGROUP=y
```

#### 3. 存储驱动
```
CONFIG_OVERLAY_FS=y
CONFIG_DM_THIN_PROVISIONING=y
CONFIG_MD=y
```

#### 4. 网络功能
```
CONFIG_VETH=y
CONFIG_BRIDGE=y
CONFIG_NETFILTER=y
CONFIG_NETFILTER_XT_MATCH_*  # 各种匹配器
CONFIG_NF_NAT=y
CONFIG_NF_NAT_IPV4=y
CONFIG_NF_NAT_IPV6=y
CONFIG_IP_NF_IPTABLES=y
CONFIG_IP6_NF_IPTABLES=y
```

#### 5. 安全功能
```
CONFIG_KEYS=y
CONFIG_SECCOMP=y
CONFIG_SECURITY_APPARMOR=y  # 可选，但推荐
```

## 实现方案

### 方案 1：修改内核配置文件（推荐）

#### 步骤 1：找到内核配置文件

```bash
# 进入 Android 源码目录
cd $ANDROID_ROOT/kernel/oneplus/sdm845/

# 查找内核配置文件
ls arch/arm64/configs/ | grep fajita
```

可能的配置文件名：
- `fajita_defconfig`
- `lineageos_fajita_defconfig`
- `sdm845_defconfig`

#### 步骤 2：添加 Docker 内核选项

编辑内核配置文件，添加上述必需的内核选项：

```bash
# 编辑配置文件
vim arch/arm64/configs/fajita_defconfig
```

添加以下内容：
```
# Docker 支持
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
CONFIG_USER_NS=y
CONFIG_CGROUPS=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CPUSETS=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_MEMCG=y
CONFIG_BLK_CGROUP=y
CONFIG_OVERLAY_FS=y
CONFIG_DM_THIN_PROVISIONING=y
CONFIG_MD=y
CONFIG_VETH=y
CONFIG_BRIDGE=y
CONFIG_NETFILTER=y
CONFIG_NF_NAT=y
CONFIG_NF_NAT_IPV4=y
CONFIG_NF_NAT_IPV6=y
CONFIG_IP_NF_IPTABLES=y
CONFIG_IP6_NF_IPTABLES=y
CONFIG_KEYS=y
CONFIG_SECCOMP=y
CONFIG_SECURITY_APPARMOR=y
```

#### 步骤 3：重新编译内核

```bash
# 进入 Android 源码目录
cd $ANDROID_ROOT

# 设置环境
source build/envsetup.sh
lunch fajita-userdebug

# 编译内核
make bootimage -j$(nproc)
```

#### 步骤 4：更新 hybris-boot.img

编译完成后，新的内核镜像会在：
```
out/target/product/fajita/boot.img
```

需要将这个文件复制到 SailfishOS 构建环境中：
```bash
# 复制到 hybris-boot.img 位置
cp out/target/product/fajita/boot.img $ANDROID_ROOT/hybris/droid-configs/installroot/boot/hybris-boot.img
```

### 方案 2：修改内核配置验证脚本

如果不想重新编译内核，可以修改内核配置验证脚本，放宽要求：

```bash
# 编辑验证脚本
vim $ANDROID_ROOT/hybris/mer-kernel-check/mer_verify_kernel_config
```

添加或修改以下内容：
```python
# Docker 支持的内核选项（可选，不强制要求）
docker_kernel_options = [
    'CONFIG_NAMESPACES',
    'CONFIG_UTS_NS',
    'CONFIG_IPC_NS',
    'CONFIG_PID_NS',
    'CONFIG_NET_NS',
    'CONFIG_USER_NS',
    'CONFIG_OVERLAY_FS',
    'CONFIG_VETH',
    'CONFIG_BRIDGE',
    'CONFIG_NETFILTER',
    'CONFIG_NF_NAT',
]

# 将这些选项标记为警告而不是错误
for option in docker_kernel_options:
    if option not in kernel_config:
        print(f"WARNING: {option} not set (Docker may not work)")
```

**注意**：这只是跳过检查，如果内核实际不支持这些功能，docker 还是无法运行。

### 方案 3：使用 Podman + rootless 模式

如果内核功能有限，可以使用 Podman 的 rootless 模式，它对内核功能的要求较低：

```bash
# 在 kickstart 文件中添加
%packages
patterns-sailfish-device-configuration-fajita
podman
slirp4netns  # 用户态网络
fuse-overlayfs  # 用户态存储驱动
%end
```

## 实施步骤（推荐方案 1）

### 1. 检查当前内核配置

```bash
# 在 Android 源码目录中
cd $ANDROID_ROOT/kernel/oneplus/sdm845/

# 查看当前配置
cat arch/arm64/configs/fajita_defconfig | grep -E "NAMESPACES|CGROUP|OVERLAY|VETH|BRIDGE"
```

### 2. 修改内核配置

```bash
# 编辑配置文件
vim arch/arm64/configs/fajita_defconfig

# 添加 Docker 内核选项（见上方）
```

### 3. 重新编译内核

```bash
cd $ANDROID_ROOT
source build/envsetup.sh
lunch fajita-userdebug
make bootimage -j$(nproc)
```

### 4. 更新构建脚本

修改 `build-rpm.sh`，确保使用新的内核镜像：

```bash
# 在构建 RPM 包之前，复制新的内核镜像
cp out/target/product/fajita/boot.img hybris/droid-configs/installroot/boot/hybris-boot.img
```

### 5. 修改 Kickstart 文件

在 `Jolla-@RELEASE@-fajita-@ARCH@.ks` 中添加 docker 包：

```kickstart
%packages
patterns-sailfish-device-configuration-fajita
# Docker 容器支持
docker
docker-compose
%end
```

### 6. 添加后安装脚本

```kickstart
%post --erroronfail
# ... 现有内容 ...

# Docker 配置
systemctl enable docker
systemctl start docker

# 添加用户到 docker 组
usermod -aG docker nemo

%end
```

### 7. 测试构建

```bash
# 运行构建
sudo bash ./run-mic1.sh

# 检查生成的镜像
ls -lh sfe-fajita-5.0.0.73/
```

### 8. 验证 Docker 功能

在设备上测试：
```bash
# 检查内核支持
docker info

# 运行测试容器
docker run --rm hello-world
```

## 注意事项

1. **Android 内核限制**：Android 内核可能缺少某些 docker 需要的功能，特别是 overlayfs
2. **存储空间**：移动设备存储空间有限，docker 镜像和容器会占用大量空间
3. **性能**：在移动设备上运行 docker 容器可能会有性能问题
4. **安全性**：需要考虑容器逃逸风险，特别是在移动设备上
5. **电源管理**：docker 守护进程可能会影响电池寿命
6. **SELinux/Permissive**：Android 内核可能需要设置为 permissive 模式才能运行 docker

## 验证清单

在部署前，确保：

- [ ] 内核配置包含所有必需的选项
- [ ] 内核成功编译
- [ ] hybris-boot.img 已更新
- [ ] docker 包已添加到 kickstart 文件
- [ ] 构建成功完成
- [ ] 在设备上可以运行 `docker info`
- [ ] 可以成功运行测试容器

## 相关资源

- [Docker 内核要求](https://docs.docker.com/engine/install/linux-postinstall/#kernel-requirements)
- [SailfishOS HADK 文档](https://docs.sailfishos.org/HADK/)
- [Hybris 项目](https://github.com/mer-hybris)
- [OnePlus 6T 内核源码](https://github.com/OnePlusSE/android_kernel_oneplus_sdm845)
