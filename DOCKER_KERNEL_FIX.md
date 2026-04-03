# 一加6T Docker 内核支持 - 完整指南

## 当前状态

基于一加6T实际检查结果，内核已支持大部分Docker功能，但缺少以下配置：

### 缺失的关键配置（Generally Necessary）
- CONFIG_BRIDGE_NETFILTER
- CONFIG_IP6_NF_TARGET_MASQUERADE
- CONFIG_NETFILTER_XT_MATCH_ADDRTYPE
- CONFIG_NETFILTER_XT_MATCH_IPVS
- CONFIG_POSIX_MQUEUE
- CONFIG_IP6_NF_NAT

### 缺失的可选配置（Optional Features）
- CONFIG_CFQ_GROUP_IOSCHED
- CONFIG_BLK_CGROUP
- CONFIG_BLK_DEV_THROTTLING
- CONFIG_CGROUP_PERF
- CONFIG_CGROUP_HUGETLB
- CONFIG_CGROUP_NET_PRIO
- CONFIG_CFS_BANDWIDTH
- CONFIG_SECURITY_APPARMOR
- CONFIG_EXT4_FS_POSIX_ACL
- CONFIG_VXLAN
- CONFIG_BRIDGE_VLAN_FILTERING
- CONFIG_IPVLAN
- CONFIG_DUMMY
- CONFIG_BTRFS_FS

### 网络配置问题
- sysctl net.ipv4.ip_forward: disabled
- sysctl net.ipv6.conf.all.forwarding: disabled
- sysctl net.ipv6.conf.default.forwarding: disabled

## 快速修复

### 方案 1：使用 GitHub Actions 自动编译（推荐）

1. **触发编译**
   ```bash
   cd /home/user/.openclaw/workspace/fajita-sfos-ci
   git add .
   git commit -m "Update Docker kernel support v2"
   git push
   ```

2. **在 GitHub 上触发 Actions**
   - 访问 Actions 页面
   - 选择 "Build Hybris Boot Image" 工作流
   - 点击 "Run workflow"

3. **下载产物**
   - 编译完成后，下载 `kernel-fajita-5.0.0.73` 和 `kernel-config-fajita`

4. **刷入设备**
   ```bash
   # 进入 fastboot 模式
   adb reboot bootloader

   # 刷入新的内核镜像
   fastboot flash boot hybris-boot.img

   # 重启
   fastboot reboot
   ```

### 方案 2：本地编译

1. **克隆内核源码**
   ```bash
   mkdir -p ~/android
   cd ~/android
   git clone --depth 1 --single-branch --branch lineage-16.0 \
     https://github.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable.git \
     kernel/oneplus/sdm845
   ```

2. **应用 Docker 补丁**
   ```bash
   cd ~/android/kernel/oneplus/sdm845/
   bash /home/user/.openclaw/workspace/fajita-sfos-ci/scripts/apply-docker-kernel-patch-v2.sh
   ```

3. **编译内核**
   ```bash
   # 安装依赖
   sudo apt-get install -y \
     gcc-12-aarch64-linux-gnu \
     g++-12-aarch64-linux-gnu \
     build-essential \
     bc \
     bison \
     flex \
     libssl-dev

   # 创建符号链接
   sudo ln -sf /usr/bin/aarch64-linux-gnu-gcc-12 /usr/bin/aarch64-linux-gnu-gcc
   sudo ln -sf /usr/bin/aarch64-linux-gnu-g++-12 /usr/bin/aarch64-linux-gnu-g++

   # 设置环境
   export ARCH=arm64
   export SUBARCH=arm64
   export CROSS_COMPILE=aarch64-linux-gnu-
   export CC=aarch64-linux-gnu-gcc

   # 编译
   make fajita_defconfig
   make -j$(nproc) Image.gz
   ```

4. **打包 boot.img**
   ```bash
   # 需要原厂 boot.img 和 mkbootimg 工具
   # 具体步骤见 BUILD_HYBRIS_BOOT.md
   ```

## 配置网络

刷入新内核后，在设备上运行：

```bash
# 启用网络转发
sudo bash /home/user/.openclaw/workspace/fajita-sfos-ci/scripts/enable-docker-networking.sh

# 或者手动启用
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv6.conf.default.forwarding=1
```

## 验证 Docker 支持

### 1. 检查内核配置

```bash
# 下载 check-config.sh
wget https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh

# 运行检查
sh check-config.sh
```

### 2. 测试 Docker

```bash
# 安装 Docker（如果未安装）
sudo zypper in docker

# 启动 Docker 服务
sudo systemctl enable docker
sudo systemctl start docker

# 添加用户到 docker 组
sudo usermod -aG docker nemo

# 测试运行容器
docker run --rm hello-world
```

### 3. 测试网络功能

```bash
# 测试 bridge 网络
docker network create test-net
docker run --rm --network test-net alpine ping -c 3 8.8.8.8
docker network rm test-net

# 测试 overlay 存储
docker run --rm -v /tmp/test:/data alpine touch /data/test
```

## 新增配置说明

### 网络过滤
- **CONFIG_BRIDGE_NETFILTER**: 允许 bridge 网络使用 iptables 规则
- **CONFIG_IP6_NF_TARGET_MASQUERADE**: IPv6 NAT 支持
- **CONFIG_NETFILTER_XT_MATCH_ADDRTYPE**: 地址类型匹配
- **CONFIG_NETFILTER_XT_MATCH_IPVS**: IPVS 负载均衡支持

### 存储和IO
- **CONFIG_BLK_CGROUP**: 块设备 cgroup 控制
- **CONFIG_BLK_DEV_THROTTLING**: 块设备节流
- **CONFIG_CFQ_GROUP_IOSCHED**: CFQ 调度器组支持

### Cgroups
- **CONFIG_CGROUP_PERF**: 性能监控 cgroup
- **CONFIG_CGROUP_HUGETLB**: 大页内存 cgroup
- **CONFIG_CGROUP_NET_PRIO**: 网络优先级 cgroup
- **CONFIG_CFS_BANDWIDTH**: CFS 带宽控制

### 安全
- **CONFIG_SECURITY_APPARMOR**: AppArmor 安全框架

### 文件系统
- **CONFIG_EXT4_FS_POSIX_ACL**: EXT4 POSIX ACL 支持

### 网络驱动
- **CONFIG_VXLAN**: VXLAN 虚拟网络
- **CONFIG_BRIDGE_VLAN_FILTERING**: Bridge VLAN 过滤
- **CONFIG_IPVLAN**: IPVLAN 网络驱动
- **CONFIG_DUMMY**: 虚拟网络设备

### 存储驱动
- **CONFIG_BTRFS_FS**: Btrfs 文件系统支持

## 故障排除

### Docker 无法启动

```bash
# 检查 Docker 服务状态
sudo systemctl status docker

# 查看日志
sudo journalctl -u docker -n 50

# 检查内核配置
zcat /proc/config.gz | grep -E "NAMESPACES|CGROUP|OVERLAY"
```

### 网络问题

```bash
# 检查网络转发
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding

# 检查 iptables 规则
sudo iptables -L -n
sudo ip6tables -L -n

# 重启 Docker 网络
sudo systemctl restart docker
```

### 存储问题

```bash
# 检查 overlayfs 支持
lsmod | grep overlay

# 检查磁盘空间
df -h

# 清理 Docker 缓存
docker system prune -a
```

## 相关资源

- [Docker 内核要求](https://docs.docker.com/engine/install/linux-postinstall/#kernel-requirements)
- [SailfishOS HADK 文档](https://docs.sailfishos.org/HADK/)
- [OnePlus 6T 内核源码](https://github.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable)
- [check-config.sh](https://github.com/docker/docker/blob/master/contrib/check-config.sh)

## 注意事项

⚠️ **重要提醒**：
- 编译需要大量磁盘空间（2-3GB）
- 编译时间较长（30-60分钟）
- 刷入前务必备份原 boot 镜像
- 可能会导致设备变砖（谨慎操作）
- 网络转发配置需要 root 权限

## 下一步

配置完成后，可以：
1. 部署 Waydroid
2. 安装 Flowpilot
3. 构建巡查机器人系统
