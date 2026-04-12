# 纯 Linux 内核构建方案分析

## 背景

当前 GitHub Actions 构建 Android 内核（基于 Linux 4.9），用户询问是否可以构建纯 Linux 内核。

## 可行性分析

### Snapdragon 845 (sdm845) 在 mainline Linux 内核中的支持

**基本支持：**
- ✅ CPU、内存、基本 I/O：支持良好
- ✅ 设备树：有社区维护的设备树
- ✅ 启动：可以正常启动

**驱动支持：**
- ⚠️ GPU (Adreno 630)：有基本支持，但可能不完整
- ⚠️ 摄像头：支持有限
- ⚠️ 传感器：支持有限
- ⚠️ 调制解调器：需要特定驱动
- ✅ Wi-Fi、蓝牙：支持良好
- ✅ USB、存储：支持良好

### 社区项目

**PostmarketOS：**
- 对 OnePlus 6/6T 有良好支持
- 使用 mainline Linux 内核（6.x）
- 设备树：`linux-postmarketos-qcom-sdm845`

**Ubuntu Touch：**
- 对 OnePlus 6/6T 有支持
- 使用 mainline Linux 内核
- 设备树：`linux-ubuntu-touch`

**LineageOS：**
- 使用 Android 内核（不是 mainline）
- 但是有 mainline 内核的实验性支持

## 优势

1. **更新的内核版本**：
   - 更好的安全性（CVE 修复）
   - 更好的性能（调度器优化）
   - 更好的功能（新的系统调用、文件系统）

2. **更好的 Docker 支持**：
   - 更新的 cgroup 支持
   - 更好的 namespace 支持
   - 更好的 overlayfs 支持
   - 更新的内核特性（如 user namespaces）

3. **更少的依赖**：
   - 不需要 hybris 兼容层
   - 更简单的系统架构
   - 更少的维护成本

4. **更好的硬件支持**：
   - 更新的驱动
   - 更好的电源管理
   - 更好的性能

## 挑战

1. **硬件驱动不完整**：
   - GPU 驱动可能不完整（影响图形性能）
   - 摄像头驱动可能不支持（影响拍照）
   - 传感器驱动可能不支持（影响自动亮度、陀螺仪等）

2. **设备树需要适配**：
   - 需要找到或创建正确的设备树
   - 可能需要修改设备树以匹配硬件

3. **SailfishOS 兼容性**：
   - SailfishOS 可能依赖 Android 内核的某些特性
   - 可能需要修改 SailfishOS 的用户空间
   - 可能需要重新编译某些组件

4. **调试困难**：
   - 如果出现问题，调试可能更困难
   - 社区支持可能较少

## 实施方案

### 方案 1：使用 PostmarketOS 的内核

**优点：**
- 已经经过测试
- 有社区支持
- 设备树已经适配

**缺点：**
- 可能不是最新的内核版本
- 可能需要适配 SailfishOS

**步骤：**
1. 克隆 PostmarketOS 的内核源码
2. 修改内核配置以支持 SailfishOS
3. 编译内核
4. 打包 boot.img
5. 测试

### 方案 2：使用 Ubuntu Touch 的内核

**优点：**
- 已经经过测试
- 有社区支持
- 设备树已经适配

**缺点：**
- 可能不是最新的内核版本
- 可能需要适配 SailfishOS

**步骤：**
1. 克隆 Ubuntu Touch 的内核源码
2. 修改内核配置以支持 SailfishOS
3. 编译内核
4. 打包 boot.img
5. 测试

### 方案 3：使用 mainline Linux 内核

**优点：**
- 最新的内核版本
- 最新的功能和安全修复
- 最好的性能

**缺点：**
- 需要自己适配设备树
- 需要自己适配驱动
- 调试困难

**步骤：**
1. 克隆 mainline Linux 内核源码
2. 添加 Snapdragon 845 的设备树
3. 添加必要的驱动
4. 修改内核配置
5. 编译内核
6. 打包 boot.img
7. 测试

## 建议

**短期方案（推荐）：**
- 使用 PostmarketOS 或 Ubuntu Touch 的内核
- 这些内核已经经过测试，有社区支持
- 可以快速验证可行性

**长期方案：**
- 使用 mainline Linux 内核
- 需要更多时间和精力
- 但是可以获得最好的性能和功能

## 下一步

1. **调研 PostmarketOS 的内核**：
   - 查看内核版本
   - 查看设备树
   - 查看驱动支持

2. **调研 Ubuntu Touch 的内核**：
   - 查看内核版本
   - 查看设备树
   - 查看驱动支持

3. **选择一个方案**：
   - 根据调研结果选择一个方案
   - 开始实施

4. **测试**：
   - 编译内核
   - 打包 boot.img
   - 刷入设备
   - 测试功能

## 结论

构建纯 Linux 内核是可行的，但是需要考虑硬件驱动和 SailfishOS 兼容性。建议先使用 PostmarketOS 或 Ubuntu Touch 的内核进行测试，然后再考虑使用 mainline Linux 内核。
