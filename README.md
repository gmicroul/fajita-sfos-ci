# fajita-sfos-ci — Sailfish OS 刷机包 CI

为 OnePlus 6T (**fajita**) / OnePlus 6 (**enchilada**) 自动构建 Sailfish OS 可刷写镜像的
GitHub Actions 项目，基于 Jolla HADK 流程：`mic create fs` + Kickstart + hybris-installer。

## 两条构建流水线

| Workflow | 产物 | 说明 |
|---|---|---|
| `fajita-ci.yml` / `enchilada-ci.yml` | 标准 Sailfish OS 刷机包 | 从 Jolla/OBS 源组装 rootfs，打成 `*-SLOT_a.zip` 并发布 Release |
| `fajita-docker-ci.yml` | **SailfishOS 5.0.0.67 fajita Docker 内核刷机包** | 标准镜像 + docker-kernel-oneplus6t 内核模块 + Docker boot 镜像 |

## Docker 内核刷机包（fajita-docker-ci.yml）

### 原理

1. 从 `gmicroul/fajita-sfos-docker-ci` 的 release
   `sailfishos-docker-5.0.0.67-fajita` 下载三个产物：
   - `boot_a-docker-v2.img` — Docker 内核 boot 镜像（sha256 `b17c9fbd…`）
   - `docker-kernel-oneplus6t-4.9.209_docker-1.g5eb4c03127.aarch64.rpm` —
     配套内核模块 + 包内 boot.img + 设备端安装/回滚脚本（sha256 `b926aefd…`）
   - `boot_a-backup-before-docker.img` — 刷机前 stock boot，预置为设备端回滚备份
2. `scripts/extract-rpm.py`（纯 Python，无 rpm/cpio 依赖）把 .rpm 的 payload 解包出来。
3. `mic create fs` 按 `Jolla-@RELEASE@-fajita-docker-@ARCH@.ks`（5.0.0.67 源）组装 rootfs；
   在 `%post --nochroot` 阶段由 `scripts/inject-docker-kernel.sh` 完成注入：
   - 内核模块 → `/lib/modules/4.9.209-hybris-g5eb4c03127-dirty/`
   - `/boot/hybris-boot.img` → 替换为 Docker boot 镜像（TWRP 安装器会把该文件刷进
     活动 slot 的 boot 分区，因此**刷完即 Docker 内核**）
   - `/root/kernel-backups/oneplus6t-docker/` → 预置 stock boot 备份 + sha256
4. `%pack` 阶段用 hybris-installer 模板打成 `sailfishos-5.0.0.67-<date>-fajita-SLOT_a.zip`
   （含 md5/sha1/sha256 校验文件），发布到 Release tag `sailfishos-docker-5.0.0.67-fajita`。

### 触发方式

- 仓库页面 **Actions → Build sailfishos-docker for fajita (5.0.0.67) → Run workflow**
- 或 repository_dispatch 事件

### 产物校验（workflow 内置）

- 下载的三个文件 sha256 与常量逐一比对，不匹配直接失败；
- 构建完成后解包刷机包，确认包内 `/boot/hybris-boot.img` 的 sha256 等于
  `b17c9fbd…`（Docker 内核），并确认内核模块已入包。

### 刷机

1. 先刷/已有 LineageOS 16.0 底包（`lineage.build.version=16.0`）。
2. TWRP 刷入 `sailfishos-5.0.0.67-*-fajita-SLOT_a.zip`（文件名中的 `SLOT_a`
   决定刷入 slot a 并设为活动 slot）。
3. 刷完即 Docker 内核；若需切回原内核，设备端执行
   `rollback-docker-kernel`（回滚备份已预置），或 `install-docker-kernel` 重新刷 Docker 内核。

## 本地构建（可选）

`*.env` 提供环境变量参考（PLATFORM_SDK_ROOT / ANDROID_ROOT / VENDOR / DEVICE /
PORT_ARCH / RELEASE），CI 内由 workflow 直接注入，不依赖这些文件。