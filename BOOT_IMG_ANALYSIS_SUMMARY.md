# Boot.img 功能分析总结

## 概述

分析了两个 boot.img 的功能和差异：
- **droid-boot.img**：Android boot.img（4.8 MB）
- **hybris-boot-latest.img**：SailfishOS boot.img（64 MB）

## 关键发现

### 1. Second 镜像

**hybris-boot-latest.img 包含 8 MB 的 Second 镜像：**
- Second 镜像是设备树（DTB）
- Magic: `d7b7ab1e`（旧格式设备树）
- Total size: 5199254 bytes
- String block size: 219279 bytes

**droid-boot.img 没有 Second 镜像：**
- Second size: 0 bytes

### 2. 内核加载地址

| 项目 | droid-boot.img | hybris-boot-latest.img |
|------|---------------|----------------------|
| Kernel load address | 0x00008000 | 0x80008000 |
| Ramdisk load address | 0x01000000 | 0x81000000 |

**分析：**
- droid-boot.img 使用物理地址（Android 内核）
- hybris-boot-latest.img 使用虚拟地址（Linux 内核）

### 3. 内核大小

| 项目 | droid-boot.img | hybris-boot-latest.img | 差异 |
|------|---------------|----------------------|------|
| Kernel size | 12.6 MB | 11.3 MB | -1.3 MB |

**分析：**
- hybris-boot-latest.img 的内核比 droid-boot.img 小 1.3 MB
- 可能是内核编译不完整

### 4. Ramdisk

| 项目 | droid-boot.img | hybris-boot-latest.img | 差异 |
|------|---------------|----------------------|------|
| Ramdisk size | 15.5 MB | 7.8 MB | -7.7 MB |
| Ramdisk 格式 | 未知格式 | cpio 归档 (initramfs) | 不同 |

**分析：**
- droid-boot.img 的 ramdisk 比 hybris-boot-latest.img 大 7.7 MB
- droid-boot.img 的 ramdisk 格式未知（可能是 Android 特有格式）
- hybris-boot-latest.img 的 ramdisk 是标准的 Linux initramfs

### 5. Build Variant

| 项目 | droid-boot.img | hybris-boot-latest.img |
|------|---------------|----------------------|
| Build variant | user | userdebug |

**分析：**
- droid-boot.img 是生产版本，无调试功能
- hybris-boot-latest.img 是调试版本，有调试功能

## 功能分析

### droid-boot.img（Android）

**功能：**
1. **Android 内核**：12.6 MB，加载地址 0x00008000
2. **Android Ramdisk**：15.5 MB，包含 Android initramfs
3. **无 Second**：没有 second 镜像
4. **User 变体**：生产版本，无调试功能

**用途：**
- 启动 Android 系统
- 包含 Android initramfs
- 用于生产环境

### hybris-boot-latest.img（SailfishOS）

**功能：**
1. **SailfishOS 内核**：11.3 MB，加载地址 0x80008000
2. **SailfishOS Ramdisk**：7.8 MB，包含 SailfishOS initramfs（cpio 归档）
3. **Second 镜像**：8 MB，是设备树（DTB）
4. **Userdebug 变体**：调试版本，有调试功能

**用途：**
- 启动 SailfishOS 系统
- 包含 SailfishOS initramfs
- 包含设备树（DTB）
- 用于开发/调试环境

## 问题分析

### 当前问题

1. **内核太小**：hybris-boot-latest.img 的内核比 droid-boot.img 小 1.3 MB
2. **Second 镜像不正确**：droid-boot.img 的 second size 是 0，但 hybris-boot-latest.img 是 8 MB
3. **内核加载地址不同**：可能导致启动失败

### 可能的原因

1. **内核编译不完整**：hybris-boot-latest.img 的内核可能缺少某些驱动或模块
2. **Second 镜像不正确**：hybris-boot-latest.img 的 second 镜像可能不正确
3. **内核加载地址错误**：hybris-boot-latest.img 的内核加载地址可能不正确

## 建议

### 1. 检查内核配置

- 检查 hybris-boot-latest.img 的内核配置
- 确保启用了所有必要的驱动和功能
- 检查是否有编译错误或警告

### 2. 检查 Second 镜像

- hybris-boot-latest.img 的 second 镜像是设备树（DTB）
- droid-boot.img 没有 second 镜像
- 需要确认是否需要 second 镜像

### 3. 检查内核加载地址

- 检查 hybris-boot-latest.img 的内核加载地址是否正确
- 如果不正确，需要修改内核配置或 boot.img 打包参数

### 4. 使用 droid-boot.img 的配置

- 使用 droid-boot.img 的配置重新打包 hybris-boot.img
- 确保所有参数和 droid-boot.img 一致
- 只替换内核，保留其他部分

## 下一步

1. 检查 hybris-boot-latest.img 的内核配置
2. 检查是否需要 second 镜像
3. 使用 droid-boot.img 的配置重新打包 hybris-boot.img
4. 测试新的 hybris-boot.img
