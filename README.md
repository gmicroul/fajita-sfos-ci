# fajita-sfos-ci — Sailfish OS 刷机包 CI

为 OnePlus 6T (**fajita**) / OnePlus 6 (**enchilada**) 自动构建 Sailfish OS 可刷写镜像的
GitHub Actions 项目，基于 Jolla HADK 流程：`mic create fs` + Kickstart + hybris-installer。

## 两条构建流水线

| Workflow | 产物 | 说明 |
|---|---|---|
| `fajita-ci.yml` / `enchilada-ci.yml` | 标准 Sailfish OS 刷机包 | 从 Jolla/OBS 源组装 rootfs，打成 `*-SLOT_a.zip` 并发布 Release |
| `fajita-docker-ci.yml` | **SailfishOS 5.1.0.11 fajita Docker 内核刷机包** | 标准镜像 + docker-kernel-oneplus6t 内核模块 + Docker boot 镜像 |

> **为什么基础版本是 5.1.0.11 而不是 5.0.0.67？**
> fajita 社区适配包（2026-08 重编译，OBS 各分支同一版本）要求 `pulseaudio >= 15.0`，
> 而 5.0.0.67 官方源只有 pulseaudio 14.2，依赖无法满足，构建必然失败。
> 5.1.0.11 提供 pulseaudio 17.0，且社区适配同为 hybris 16.0，Docker 内核完全兼容。

## Docker 内核刷机包（fajita-docker-ci.yml）

### 原理

1. 从 `gmicroul/fajita-sfos-docker-ci` 的 release
   `sailfishos-docker-5.0.0.67-fajita` 下载三个**内核级**产物（hybris 16.0，与 5.1 基础兼容）：
   - `boot_a-docker-v2.img` — Docker 内核 boot 镜像（sha256 `b17c9fbd…`）
   - `docker-kernel-oneplus6t-4.9.209_docker-1.g5eb4c03127.aarch64.rpm` —
     配套内核模块 + 包内 boot.img + 设备端安装/回滚脚本（sha256 `b926aefd…`）
   - `boot_a-backup-before-docker.img` — 刷机前 stock boot，预置为设备端回滚备份
2. `scripts/extract-rpm.py`（纯 Python，无 rpm/cpio 依赖）把 .rpm 的 payload 解包出来。
3. `mic create fs` 按 `Jolla-@RELEASE@-fajita-docker-@ARCH@.ks`（5.1.x 源）组装 rootfs；
   在 `%post --nochroot` 阶段由 `scripts/inject-docker-kernel.sh` 完成注入：
   - 内核模块 → `/lib/modules/4.9.209-hybris-g5eb4c03127-dirty/`
   - `/boot/hybris-boot.img` → 替换为 Docker boot 镜像（TWRP 安装器会把该文件刷进
     活动 slot 的 boot 分区，因此**刷完即 Docker 内核**）
   - `/root/kernel-backups/oneplus6t-docker/` → 预置 stock boot 备份 + sha256
4. `%pack` 阶段用 hybris-installer 模板打成 `sailfishos-5.1.0.11-<date>-fajita-SLOT_a.zip`
   （含 md5/sha1/sha256 校验文件），发布到 Release tag `sailfishos-docker-5.1.0.11-fajita`。

### 触发方式

- 仓库页面 **Actions → Build sailfishos-docker for fajita (5.1.0.11) → Run workflow**
- 或 repository_dispatch 事件
- workflow_dispatch 的 `release` 参数可覆盖基础版本（仅建议在 5.1.x 内调整，
  因为 ks 的社区/chum/storeman 源按 5.1 写死）

### 产物校验（workflow 内置）

- 下载的三个内核产物 sha256 与常量逐一比对，不匹配直接失败；
- 构建完成后解包刷机包，确认包内 `/boot/hybris-boot.img` 的 sha256 等于
  `b17c9fbd…`（Docker 内核），并确认内核模块已入包。

### 刷机

1. 先刷/已有 LineageOS 16.0 底包（`lineage.build.version=16.0`）。
2. TWRP 刷入 `sailfishos-5.1.0.11-*-fajita-SLOT_a.zip`（文件名中的 `SLOT_a`
   决定刷入 slot a 并设为活动 slot）。
3. 刷完即 Docker 内核；若需切回原内核，设备端执行
   `rollback-docker-kernel`（回滚备份已预置），或 `install-docker-kernel` 重新刷 Docker 内核。

## 已知问题：CONFIG_ANDROID_PARANOID_NETWORK（重要）

**症状**：刷 docker 包后，非 root 用户（defaultuser）无法访问外网（浏览器/curl
一律 `Permission denied`/`Could not connect`），root 正常。

**根因**：docker 内核基于 LineageOS 的 `fajita_defconfig` 编译，带上了
`CONFIG_ANDROID_PARANOID_NETWORK=y`。该选项只允许 root（或 Android `AID_INET`
gid 3003 / `AID_NET_RAW` gid 3004 组成员）创建网络套接字，而 SFOS 的
defaultuser（uid 100000）不在这些组 → 内核层面拒绝建 socket。原版 SFOS 内核该
选项为 `n`，所以原版镜像没有此问题。

**验证**（设备上）：
```bash
zcat /proc/config.gz | grep PARANOID          # =y 即中招
timeout 3 bash -c 'echo > /dev/tcp/52.30.226.232/80'   # Permission denied 即中招
```

**缓解（已内置到刷机包 ks %post，新刷机用户出厂即通）**：把 defaultuser 加入
gid 3003。ks 里的实现会在 `usermod` 前先确保 gid 3003 在 `/etc/group` 有名字
（缺则 `groupadd -g 3003 inet`），避免直接 `usermod -a -G 3003` 因组不存在而
报错；workflow 还会解包刷机包校验 `defaultuser ∈ gid 3003`，确认缓解真的进了包。

已刷机的设备（或想手动确认）执行一次即可：
```bash
devel-su
getent group 3003 >/dev/null 2>&1 || groupadd -g 3003 inet
GRP=$(getent group 3003 | cut -d: -f1)
usermod -a -G "$GRP" defaultuser
reboot
```
校验（需重新登录/重启后，补充组才会生效）：
```bash
id -G defaultuser | tr ' ' '\n' | grep -qx 3003 && echo OK
timeout 3 bash -c 'echo > /dev/tcp/52.30.226.232/80' && echo OK
```

**治本（推荐）**：重编内核时把该选项设 `n`，见 `scripts/fix-paranoid-network.sh`，
然后用新内核重新出 boot.img/rpm/刷机包。

## 本地构建（可选）

`*.env` 提供环境变量参考（PLATFORM_SDK_ROOT / ANDROID_ROOT / VENDOR / DEVICE /
PORT_ARCH / RELEASE），CI 内由 workflow 直接注入，不依赖这些文件。