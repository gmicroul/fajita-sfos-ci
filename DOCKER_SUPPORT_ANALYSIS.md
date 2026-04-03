# Docker 内核支持分析 - fajita-sfos-ci

## 项目概述

fajita-sfos-ci 是一个用于构建一加6T (fajita) 旗鱼系统的 CI 项目。

## 当前架构

### 构建流程
1. 使用 Docker 容器 `coderus/sailfishos-platform-sdk-base:latest`
2. 在容器中运行 MIC (Image Creator) 创建系统镜像
3. 使用 kickstart 文件定义要安装的包和配置

### 关键文件
- `Jolla-@RELEASE@-fajita-@ARCH@.ks` - Kickstart 配置文件
- `run-mic1.sh` - MIC 运行脚本
- `build-hal.sh` - 硬件抽象层构建脚本
- `build-rpm.sh` - RPM 包构建脚本
- `helpers/build_packages.sh` - 包构建辅助脚本

### 内核信息
- 使用 Android 内核（通过 hybris 层）
- 设备：oneplus fajita (一加6T)
- 架构：aarch64
- 内核镜像：`/boot/hybris-boot.img`

## Docker 支持需求

### 内核层面要求

Docker 需要以下内核特性：

1. **Namespaces**
   - CONFIG_NAMESPACES
   - CONFIG_UTS_NS
   - CONFIG_IPC_NS
   - CONFIG_PID_NS
   - CONFIG_NET_NS
   - CONFIG_USER_NS

2. **Cgroups**
   - CONFIG_CGROUPS
   - CONFIG_CGROUP_FREEZER
   - CONFIG_CGROUP_PIDS
   - CONFIG_CGROUP_DEVICE
   - CONFIG_CPUSETS
   - CONFIG_CGROUP_CPUACCT
   - CONFIG_MEMCG
   - CONFIG_BLK_CGROUP

3. **存储**
   - CONFIG_OVERLAY_FS (overlayfs，Docker 推荐的存储驱动)
   - CONFIG_DM_THIN_PROVISIONING (Device Mapper)
   - CONFIG_MD (Software RAID)

4. **网络**
   - CONFIG_VETH
   - CONFIG_BRIDGE
   - CONFIG_NETFILTER
   - CONFIG_NETFILTER_XT_MATCH_* (各种 netfilter 匹配器)
   - CONFIG_NF_NAT (NAT 支持)

5. **安全**
   - CONFIG_KEYS
   - CONFIG_SECCOMP
   - CONFIG_SECURITY_APPARMOR (可选，用于安全隔离)

### 用户空间要求

需要安装以下包：
- docker-ce 或 docker-engine
- docker-cli
- containerd
- docker-compose (可选)

## 实现方案

### 方案 1：修改 Kickstart 文件（推荐）

在 `Jolla-@RELEASE@-fajita-@ARCH@.ks` 的 `%packages` 部分添加 docker 相关包：

```kickstart
%packages
patterns-sailfish-device-configuration-fajita
# Docker 支持
docker
docker-compose
%end
```

**优点**：
- 简单直接
- 不需要修改内核配置
- 旗鱼系统可能已经有 docker 包

**缺点**：
- 依赖旗鱼系统仓库中有 docker 包
- 可能需要额外的配置

### 方案 2：添加自定义内核模块

如果 Android 内核缺少某些 docker 需要的功能，需要：

1. 找到内核源码（通常在 `$ANDROID_ROOT/kernel` 或 `$ANDROID_ROOT/kernel/oneplus/sdm845`）
2. 修改内核配置文件（`arch/arm64/configs/fajita_defconfig`）
3. 添加缺失的内核选项
4. 重新编译内核

**需要检查的内核配置位置**：
- `$ANDROID_ROOT/kernel/oneplus/sdm845/arch/arm64/configs/fajita_defconfig`
- `$ANDROID_ROOT/kernel/oneplus/sdm845/arch/arm64/configs/lineageos_fajita_defconfig`

**示例配置添加**：
```
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
CONFIG_USER_NS=y
CONFIG_OVERLAY_FS=y
CONFIG_VETH=y
CONFIG_BRIDGE=y
CONFIG_NETFILTER=y
CONFIG_NF_NAT=y
```

### 方案 3：使用 Podman 替代 Docker

Podman 是 docker 的无守护进程替代品，可能更适合移动设备：

```kickstart
%packages
patterns-sailfish-device-configuration-fajita
# 容器支持
podman
%end
```

## 实施步骤

### 第一步：检查当前内核配置

```bash
# 在构建环境中检查内核配置
cat /proc/config.gz | gunzip | grep -E "NAMESPACES|CGROUP|OVERLAY|VETH|BRIDGE"
```

### 第二步：检查旗鱼系统仓库

```bash
# 在 SDK 中搜索 docker 包
sb2 -t oneplus-fajita-aarch64 zypper se docker
sb2 -t oneplus-fajita-aarch64 zypper se podman
sb2 -t oneplus-fajita-aarch64 zypper se container
```

### 第三步：修改 Kickstart 文件

如果仓库中有 docker 包，修改 `Jolla-@RELEASE@-fajita-@ARCH@.ks`：

```kickstart
%packages
patterns-sailfish-device-configuration-fajita
# Docker 容器支持
docker
docker-compose
# 或者使用 Podman
# podman
%end
```

### 第四步：添加后安装脚本（可选）

在 `%post` 部分添加 docker 配置：

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

### 第五步：测试构建

```bash
# 运行构建
sudo bash ./run-mic1.sh

# 检查生成的镜像
ls -lh sfe-fajita-5.0.0.73/
```

## 注意事项

1. **Android 内核限制**：Android 内核可能缺少某些 docker 需要的功能，特别是 overlayfs
2. **存储空间**：移动设备存储空间有限，docker 镜像和容器会占用大量空间
3. **性能**：在移动设备上运行 docker 容器可能会有性能问题
4. **安全性**：需要考虑容器逃逸风险，特别是在移动设备上
5. **电源管理**：docker 守护进程可能会影响电池寿命

## 推荐方案

基于当前分析，推荐以下方案：

1. **首先尝试方案 1**：在 kickstart 文件中添加 docker 包
2. **如果失败，尝试方案 3**：使用 podman 替代 docker
3. **最后考虑方案 2**：修改内核配置（最复杂，需要重新编译内核）

## 下一步行动

1. 检查旗鱼系统仓库中是否有 docker/podman 包
2. 检查当前 Android 内核是否支持 docker 需要的功能
3. 根据检查结果选择合适的方案
4. 修改相应的配置文件
5. 测试构建并验证 docker 功能

## 相关资源

- [Docker 内核要求](https://docs.docker.com/engine/install/linux-postinstall/#kernel-requirements)
- [旗鱼系统文档](https://docs.sailfishos.org/)
- [Hybris 项目](https://github.com/mer-hybris)
