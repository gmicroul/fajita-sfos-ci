# 一加6T Docker内核编译调试方案

## 🎯 目标
编译支持Docker的Sailfish OS内核，纠正之前可能的偏差

## 📋 编译步骤

### 阶段1: 环境准备
- [ ] 检查编译环境依赖
- [ ] 安装交叉编译工具链
- [ ] 验证内核源码可用性

### 阶段2: 内核配置
- [ ] 应用Docker内核补丁 (apply-docker-kernel-patch-v2.sh)
- [ ] 验证补丁应用结果
- [ ] 检查关键Docker配置选项

### 阶段3: 编译优化
- [ ] 清理问题驱动 (clean-kernel-drivers-v2.sh)
- [ ] 创建空的trace头文件
- [ ] 配置编译参数
- [ ] 编译内核

### 阶段4: 引导镜像处理
- [ ] 下载LineageOS boot.img
- [ ] 提取原boot.img内容
- [ ] 替换新编译的内核
- [ ] 重新打包hybris-boot.img

### 阶段5: 验证测试
- [ ] 验证hybris-boot.img完整性
- [ ] 检查内核配置
- [ ] 测试Docker基本功能

## 🔧 关键修复点

### 1. Docker配置完整性
确保以下关键配置已启用：
- `CONFIG_NAMESPACES=y` - 命名空间支持
- `CONFIG_CGROUPS=y` - 控制组支持  
- `CONFIG_OVERLAY_FS=y` - Overlay文件系统
- `CONFIG_VETH=y` - 虚拟以太网设备
- `CONFIG_BRIDGE=y` - 网桥支持

### 2. 编译错误修复
- 处理trace头文件缺失问题
- 禁用stack protector避免编译器兼容性问题
- 清理有问题的驱动模块

### 3. 引导镜像兼容性
- 保持原boot.img的ramdisk和dtb
- 使用正确的cmdline参数
- 确保设备树兼容

## 🚀 开始编译

运行本地编译脚本：
```bash
cd /home/user/.hermes/fajita-sfos-ci
./local-build-docker-kernel.sh
```

## 📊 预期输出
- `hybris-boot.img` - 完整引导镜像
- `Image.gz` - 内核镜像
- 编译日志和错误报告

## ⚠️ 注意事项
- 编译需要大量磁盘空间 (40-60GB)
- 编译时间较长 (2-4小时)
- 需要稳定的网络连接
- 建议分阶段执行便于调试

## 🔍 调试方法
如果编译失败：
1. 检查具体错误信息
2. 分步执行脚本
3. 验证中间文件生成
4. 查看内核配置状态