# Fajita SFOS CI - OnePlus 6T 巡查机器人项目

基于 OnePlus 6T (fajita) 的智能巡查机器人，使用 SailfishOS + Docker + Waydroid + Flowpilot 架构。

## 🏗️ 系统架构

```
一加6T硬件 (sdm845)
└── SailfishOS (Linux内核 + Docker支持)
    ├── Docker 容器
    │   ├── 视觉AI服务
    │   ├── 导航服务
    │   ├── 通信服务
    │   └── Web控制界面
    └── Waydroid (Android容器)
        └── Flowpilot
            ├── 视觉识别
            ├── 目标检测
            └── 行为分析
```

## 📁 项目结构

```
fajita-sfos-ci/
├── .github/workflows/
│   ├── build-hybris-boot.yml      # GitHub Actions 编译配置
│   ├── build-mido.yml             # Mido 设备 CI
│   ├── enchilada-ci.yml           # Enchilada 设备 CI
│   ├── fajita-ci.yml              # Fajita 设备 CI
│   ├── github-ci.yml              # GitHub CI 配置
│   ├── gitlab-ci.yml              # GitLab CI 配置
│   └── latte-ci.yml               # Latte 设备 CI
├── scripts/
│   └── apply-docker-kernel-patch.sh  # Docker 内核补丁脚本
├── helpers/
│   ├── build_packages.sh          # 包构建脚本
│   └── util.sh                    # 工具函数
├── DOCKER_KERNEL_SUPPORT.md       # Docker 内核支持文档
├── DOCKER_SUPPORT_ANALYSIS.md     # Docker 支持分析
├── BUILD_HYBRIS_BOOT.md           # 编译指南
├── QUICKSTART.md                  # 快速开始指南
├── build-hal.sh                   # HAL 构建脚本
├── build-rpm.sh                   # RPM 构建脚本
├── run-mic1.sh                    # MIC 运行脚本
├── fajita.env                     # Fajita 环境配置
├── hadk.env                       # HADK 环境配置
├── Jolla-@RELEASE@-fajita-@ARCH@.ks  # Kickstart 文件
└── VERSION                        # 版本信息
```

## 🚀 快速开始

### 1. 编译支持 Docker 的内核

#### 方式 A：GitHub Actions 自动编译（推荐）

```bash
# 1. 推送代码到 GitHub
git add .
git commit -m "Add Docker kernel support"
git push

# 2. 在 GitHub 上触发 Actions
# 访问 Actions 页面 -> Build Hybris Boot Image -> Run workflow

# 3. 下载编译产物
# hybris-boot-fajita-5.0.0.73
```

#### 方式 B：本地编译

```bash
# 1. 克隆 Android 源码
mkdir -p ~/android
cd ~/android
repo init -u https://github.com/LineageOS/android.git -b lineage-17.1
repo sync -c -j4

# 2. 应用 Docker 内核补丁
cd ~/android
bash scripts/apply-docker-kernel-patch.sh

# 3. 编译内核
source build/envsetup.sh
lunch fajita-userdebug
make bootimage -j$(nproc)

# 4. 提取 boot.img
cp out/target/product/fajita/boot.img ~/hybris-boot.img
```

### 2. 刷入设备

```bash
# 进入 fastboot 模式
adb reboot bootloader

# 备份原 boot 分区
fastboot boot boot.img

# 刷入新的 hybris-boot.img
fastboot flash boot hybris-boot.img

# 重启
fastboot reboot
```

### 3. 验证 Docker 支持

```bash
# 检查内核配置
zcat /proc/config.gz | grep -E "NAMESPACES|CGROUP|OVERLAY|VETH|BRIDGE"

# 测试 Docker
docker info
docker run --rm hello-world
```

### 4. 部署 Waydroid

```bash
# 安装 waydroid
sudo zypper in waydroid

# 初始化 waydroid
sudo waydroid init

# 启动 waydroid
sudo waydroid session start

# 安装 flowpilot APK
waydroid app install flowpilot.apk
```

## 📋 开发计划

### 阶段 1：基础系统 ✅
- [x] 编译支持 Docker 的内核
- [x] 安装 SailfishOS
- [x] 配置基础服务

### 阶段 2：Waydroid 集成 🔄
- [ ] 部署 Waydroid
- [ ] 安装 Flowpilot
- [ ] 配置 GPU 加速

### 阶段 3：Docker 服务 📝
- [ ] 开发视觉 AI 服务
- [ ] 开发导航服务
- [ ] 开发 Web 控制界面

### 阶段 4：系统集成 📝
- [ ] Waydroid 和 Docker 通信
- [ ] 数据流处理
- [ ] 控制逻辑实现

### 阶段 5：硬件集成 📝
- [ ] 设计移动底盘
- [ ] 集成电机驱动
- [ ] 安装扩展传感器

## 🔧 技术栈

### 硬件
- **设备**: OnePlus 6T (fajita)
- **处理器**: Snapdragon 845 (sdm845)
- **内存**: 8GB
- **存储**: 128GB

### 软件
- **操作系统**: SailfishOS 5.0.0.73
- **容器**: Docker + Waydroid
- **视觉**: Flowpilot (基于 openpilot)
- **语言**: Python, C++, Java

### AI/ML
- **视觉识别**: Flowpilot 模型
- **导航**: SLAM, 路径规划
- **目标检测**: YOLO, SSD

## 📊 资源分配

| 组件 | 内存 | CPU | 存储 |
|------|------|-----|------|
| SailfishOS | 512MB | 5% | 2GB |
| Docker 服务 | 2GB | 30% | 5GB |
| Waydroid | 3GB | 40% | 4GB |
| Flowpilot | 1.5GB | 20% | 2GB |
| **总计** | **7GB** | **95%** | **13GB** |

## 🎯 应用场景

1. **室内巡逻**
   - 办公室、仓库、商场
   - 异常行为检测
   - 设备状态监控

2. **安防监控**
   - 移动监控点
   - 人脸识别
   - 入侵检测

3. **环境监测**
   - 温湿度、空气质量
   - 气体泄漏检测
   - 火灾预警

4. **设备巡检**
   - 仪表读数
   - 设备状态
   - 异常声音检测

## ⚠️ 注意事项

1. **编译要求**
   - 磁盘空间：40-60GB
   - 编译时间：2-4小时
   - 网络连接：稳定

2. **刷入风险**
   - 可能导致设备变砖
   - 务必备份原 boot 镜像
   - 谨慎操作

3. **性能限制**
   - 内存限制：8GB
   - 散热问题：持续运行会发热
   - 续航问题：需要大容量电池

## 📚 相关资源

- [SailfishOS HADK 文档](https://docs.sailfishos.org/HADK/)
- [OnePlus 6T 内核源码](https://github.com/OnePlusSE/android_kernel_oneplus_sdm845)
- [Flowpilot 项目](https://github.com/flowdriveai/flowpilot)
- [Docker 内核要求](https://docs.docker.com/engine/install/linux-postinstall/#kernel-requirements)
- [Hybris 项目](https://github.com/mer-hybris)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 📞 联系方式

- GitHub: [你的用户名]
- Email: [你的邮箱]

---

**注意**: 本项目仅供学习和研究使用，使用时请遵守当地法律法规。
