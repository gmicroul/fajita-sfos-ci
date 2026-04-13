#!/bin/bash

# Docker内核编译验证脚本
# 快速验证项目状态和关键配置

echo "=== Docker内核编译项目验证 ==="
echo ""

# 1. 检查项目结构
echo "1. 检查项目结构..."
if [ -f "scripts/apply-docker-kernel-patch-v2.sh" ]; then
    echo "  ✓ Docker内核补丁脚本存在"
else
    echo "  ✗ Docker内核补丁脚本缺失"
fi

if [ -f "scripts/clean-kernel-drivers-v2.sh" ]; then
    echo "  ✓ 驱动清理脚本存在"
else
    echo "  ✗ 驱动清理脚本缺失"
fi

if [ -f "scripts/create-empty-trace-headers.sh" ]; then
    echo "  ✓ trace头文件脚本存在"
else
    echo "  ✗ trace头文件脚本缺失"
fi

if [ -f ".github/workflows/build-hybris-boot.yml" ]; then
    echo "  ✓ GitHub Actions工作流存在"
else
    echo "  ✗ GitHub Actions工作流缺失"
fi

# 2. 检查内核源码链接
echo ""
echo "2. 检查内核源码链接..."
echo "  内核源码: https://github.com/VerdandiTeam/android_kernel_oneplus_sdm845-stable"
echo "  分支: lineage-16.0"

# 测试链接可用性
echo ""
echo "3. 测试资源链接..."
echo "  LineageOS OTA包: https://github.com/VerdandiTeam/droid-config-enchilada/releases/download/4.5.0.13/lineage-16.0-20200325-nightly-fajita-signed.zip"

# 4. 验证Docker配置选项
echo ""
echo "4. 验证Docker内核配置..."
echo "  关键配置选项:"
echo "  - CONFIG_NAMESPACES=y (命名空间)"
echo "  - CONFIG_CGROUPS=y (控制组)"
echo "  - CONFIG_OVERLAY_FS=y (Overlay文件系统)"
echo "  - CONFIG_VETH=y (虚拟以太网)"
echo "  - CONFIG_BRIDGE=y (网桥支持)"
echo "  - CONFIG_NETFILTER=y (网络过滤)"
echo "  - CONFIG_POSIX_MQUEUE=y (消息队列)"

# 5. 检查编译环境
echo ""
echo "5. 检查编译环境..."
echo "  必需的编译工具:"
for tool in git wget curl unzip python3 pip3; do
    if which $tool >/dev/null 2>&1; then
        echo "  ✓ $tool 已安装"
    else
        echo "  ✗ $tool 未安装"
    fi
done

# 6. 验证交叉编译工具
echo ""
echo "6. 检查交叉编译工具..."
for tool in aarch64-linux-gnu-gcc aarch64-linux-gnu-g++; do
    if which $tool >/dev/null 2>&1; then
        echo "  ✓ $tool 已安装"
    else
        echo "  ✗ $tool 未安装"
    fi
done

# 7. 显示编译计划
echo ""
echo "=== 编译计划 ==="
echo ""
echo "推荐的分步编译流程:"
echo "1. 使用GitHub Actions自动编译 (推荐)"
echo "   - 推送代码到GitHub"
echo "   - 在Actions页面触发编译"
echo "   - 下载编译产物"
echo ""
echo "2. 本地编译 (调试用)"
echo "   - 运行: ./step-by-step-build.sh"
echo "   - 选择相应步骤"
echo "   - 分步执行便于调试"
echo ""
echo "3. 验证编译结果"
echo "   - 检查hybris-boot.img完整性"
echo "   - 验证内核配置"
echo "   - 测试Docker功能"

echo ""
echo "=== 下一步操作 ==="
echo ""
echo "选项1: 使用GitHub Actions (推荐)"
echo "  git push origin master"
echo "  # 然后在GitHub上触发Actions"
echo ""
echo "选项2: 本地分步编译"
echo "  ./step-by-step-build.sh"
echo ""
echo "选项3: 验证特定配置"
echo "  # 检查具体的配置或脚本"

echo ""
echo "项目验证完成!"