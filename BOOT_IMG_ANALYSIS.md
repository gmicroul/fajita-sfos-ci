# Boot.img 功能分析

## 概述

分析了两个 boot.img 的功能和差异：
- **droid-boot.img**：Android boot.img（4.8 MB）
- **hybris-boot-latest.img**：SailfishOS boot.img（64 MB）

## 详细对比

### 1. 文件大小

| 项目 | droid-boot.img | hybris-boot-latest.img | 差异 |
|------|---------------|----------------------|------|
| 总大小 | 4.8 MB | 64 MB | +59.2 MB |

### 2. 内核

| 项目 | droid-boot.img | hybris-boot-latest.img | 差异 |
|------|---------------|----------------------|------|
| Kernel size | 12.6 MB | 11.3 MB | -1.3 MB |
| Kernel load address | 0x00008000 | 0x80008000 | 不同 |
| Kernel 格式 | gzip 压缩 (Image.gz) | gzip 压缩 (Image.gz) | 相同 |

**分析：**
- droid-boot.img 的内核比 hybris-boot-latest.img 大 1.3 MB
- 内核加载地址不同（0x00008000 vs 0x80008000）
- 两个内核都是 gzip 压缩的 Image.gz

### 3. Ramdisk

| 项目 | droid-boot.img | hybris-boot-latest.img | 差异 |
|------|---------------|----------------------|------|
| Ramdisk size | 15.5 MB | 7.8 MB | -7.7 MB |
| Ramdisk load address | 0x01000000 | 0x81000000 | 不同 |
| Ramdisk 格式 | 未知格式 | cpio 归档 (initramfs) | 不同 |

**分析：**
- droid-boot.img 的 ramdisk 比 hybris-boot-latest.img 大 7.7 MB
- ramdisk 加载地址不同（0x01000000 vs 0x81000000）
- droid-boot.img 的 ramdisk 格式未知（前 16 字节为空）
- hybris-boot-latest.img 的 ramdisk 是 cpio 归档（initramfs）

### 4. Second

| 项目 | droid-boot.img | hybris-boot-latest.img | 差异 |
|------|---------------|----------------------|------|
| Second size | 0 bytes | 8 MB | +8 MB |
| Second load address | 0x00f00000 | 0x80f00000 | 不同 |

**分析：**
- droid-boot.img 没有 second
- hybris-boot-latest.img 有 8 MB 的 second

### 5. DTB

| 项目 | droid-boot.img | hybris-boot-latest.img | 差异 |
|------|---------------|----------------------|------|
| DTB size | 1 byte | 0 bytes | -1 byte |

**分析：**
- droid-boot.img 有 1 byte 的 DTB（可能是空的）
- hybris-boot-latest.img 没有 DTB

### 6. Cmdline

**droid-boot.img:**
```
androidboot.hardware=qcom androidboot.console=ttyMSM0 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 swiotlb=2048 androidboot.configfs=true androidboot.usbcontroller=a600000.dwc3 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 buildvariant=user
```

**hybris-boot-latest.img:**
```
androidboot.hardware=qcom androidboot.console=ttyMSM0 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 swiotlb=2048 androidboot.configfs=true androidboot.usbcontroller=a600000.dwc3 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 buildvariant=userdebug
```

**差异：**
- droid-boot.img: `buildvariant=user`
- hybris-boot-latest.img: `buildvariant=userdebug`

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
3. **Second 镜像**：8 MB，可能是 recovery 或其他镜像
4. **Userdebug 变体**：调试版本，有调试功能

**用途：**
- 启动 SailfishOS 系统
- 包含 SailfishOS initramfs
- 包含 second 镜像（可能是 recovery）
- 用于开发/调试环境

## 关键差异

### 1. 内核加载地址

- **droid-boot.img**: 0x00008000（物理地址）
- **hybris-boot-latest.img**: 0x80008000（虚拟地址）

**分析：**
- droid-boot.img 使用物理地址（Android 内核）
- hybris-boot-latest.img 使用虚拟地址（Linux 内核）

### 2. Ramdisk 格式

- **droid-boot.img**: 未知格式（前 16 字节为空）
- **hybris-boot-latest.img**: cpio 归档（initramfs）

**分析：**
- droid-boot.img 的 ramdisk 可能是 Android 特有的格式
- hybris-boot-latest.img 的 ramdisk 是标准的 Linux initramfs

### 3. Second 镜像

- **droid-boot.img**: 无
- **hybris-boot-latest.img**: 8 MB

**分析：**
- droid-boot.img 不需要 second 镜像
- hybris-boot-latest.img 包含 second 镜像（可能是 recovery）

### 4. Build Variant

- **droid-boot.img**: user（生产版本）
- **hybris-boot-latest.img**: userdebug（调试版本）

**分析：**
- droid-boot.img 是生产版本，无调试功能
- hybris-boot-latest.img 是调试版本，有调试功能

## 问题分析

### 当前问题

1. **内核太小**：hybris-boot-latest.img 的内核比 droid-boot.img 小 1.3 MB
2. **Second size 错误**：droid-boot.img 的 second size 是 0，但 hybris-boot-latest.img 是 8 MB
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

- 检查 hybris-boot-latest.img 的 second 镜像内容
- 确认 second 镜像是否正确
- 如果不需要 second 镜像，可以删除

### 3. 检查内核加载地址

- 检查 hybris-boot-latest.img 的内核加载地址是否正确
- 如果不正确，需要修改内核配置或 boot.img 打包参数

### 4. 使用 droid-boot.img 的配置

- 使用 droid-boot.img 的配置重新打包 hybris-boot.img
- 确保所有参数和 droid-boot.img 一致
- 只替换内核，保留其他部分

## 下一步

1. 检查 hybris-boot-latest.img 的 second 镜像内容
2. 检查 hybris-boot-latest.img 的内核配置
3. 使用 droid-boot.img 的配置重新打包 hybris-boot.img
4. 测试新的 hybris-boot.img
