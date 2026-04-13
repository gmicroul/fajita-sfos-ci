# GitHub Actions Docker内核编译触发指南

## 🎯 目标
使用GitHub Actions自动编译支持Docker的一加6T(fajita)内核

## 📋 手动触发步骤

### 1. 访问GitHub仓库
打开浏览器访问：
https://github.com/gmicroul/fajita-sfos-ci

### 2. 进入Actions页面
点击顶部的 "Actions" 标签页

### 3. 选择工作流
在左侧找到 "Build Hybris Boot Image" 工作流并点击

### 4. 手动触发编译
点击 "Run workflow" 按钮

### 5. 配置参数（可选）
- **Device**: 保持默认 `fajita`
- **Release**: 保持默认 `5.0.0.73`

### 6. 开始编译
点击绿色的 "Run workflow" 按钮

## 🔍 监控编译进度

### 查看编译日志
- 点击正在运行的workflow实例
- 查看各个步骤的详细日志
- 监控错误和警告信息

### 预期编译步骤
1. **环境准备** - 清理磁盘空间，安装依赖
2. **内核编译** - 克隆源码，应用补丁，编译内核
3. **引导镜像处理** - 下载boot.img，重新打包
4. **上传产物** - 生成hybris-boot.img

## 📦 获取编译产物

### 下载编译结果
1. 编译完成后，进入对应的workflow运行
2. 在 "Artifacts" 部分找到生成的boot镜像
3. 下载 `boot-fajita-5.0.0.73` 文件

### 产物内容
- `hybris-boot.img` - 完整的引导镜像
- 编译日志和配置信息

## ⚠️ 注意事项

### 编译时间
- 预计耗时：2-4小时
- GitHub Actions有6小时超时限制

### 资源限制
- GitHub免费账户每月2000分钟构建时间
- 单次编译约消耗60-120分钟

### 错误处理
如果编译失败：
1. 查看详细的错误日志
2. 检查网络连接（特别是下载LineageOS包）
3. 验证内核源码链接是否可用

## 🔧 编译流程详情

### 阶段1：环境准备
- 清理磁盘空间
- 安装编译工具链
- 配置交叉编译器

### 阶段2：内核编译
- 克隆LineageOS 16内核源码
- 应用Docker内核补丁
- 清理问题驱动
- 创建空的trace头文件
- 编译内核镜像

### 阶段3：引导镜像处理
- 下载LineageOS 16 boot.img
- 提取原引导镜像内容
- 替换新编译的内核
- 重新打包hybris-boot.img

### 阶段4：产物上传
- 验证编译结果
- 上传hybris-boot.img到Artifacts
- 生成构建摘要

## 🚀 快速开始

1. **立即触发**：直接访问Actions页面运行workflow
2. **等待编译完成**：监控进度和日志
3. **下载产物**：获取编译好的hybris-boot.img
4. **刷入设备**：使用fastboot刷入一加6T

## 📞 技术支持

如果遇到问题：
- 查看详细的错误日志
- 检查GitHub Actions文档
- 查看项目README.md中的说明

---

**注意**：编译产物包含支持Docker的内核，可以直接刷入一加6T设备使用。