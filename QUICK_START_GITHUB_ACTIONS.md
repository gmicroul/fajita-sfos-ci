# GitHub Actions Docker内核编译 - 快速触发指南

## 🚀 立即开始编译

### 步骤1：访问GitHub仓库
https://github.com/gmicroul/fajita-sfos-ci

### 步骤2：进入Actions页面
- 点击顶部 "Actions" 标签
- 找到 "Build Hybris Boot Image" 工作流

### 步骤3：手动触发
- 点击 "Run workflow" 
- 保持默认参数：Device=fajita, Release=5.0.0.73
- 点击绿色 "Run workflow" 按钮

## ⏱️ 编译时间
- 预计耗时：2-4小时
- 实时监控：可在Actions页面查看进度

## 📦 获取结果
编译完成后：
- 在Artifacts部分下载 `boot-fajita-5.0.0.73`
- 包含 `hybris-boot.img` (支持Docker的内核)

## 🔍 项目状态确认
当前项目已准备就绪：
- ✅ Docker内核补丁脚本就绪
- ✅ GitHub Actions工作流配置正确
- ✅ 内核源码链接有效
- ✅ LineageOS资源链接有效

## ⚠️ 注意事项
- 确保GitHub账户有足够的构建时间
- 编译过程需要稳定网络连接
- 产物可直接刷入一加6T设备

---

**立即开始**：https://github.com/gmicroul/fajita-sfos-ci/actions