# PostmarketOS 内核调研结果

## OnePlus 6/6T (fajita) PostmarketOS 内核

### 仓库信息

**仓库：** kcxt/pmos-oneplus6
**状态：** 已归档（archived: true）
**描述：** "DO NOT USE, see link below for updated install guide"
**主页：** https://wiki.postmarketos.org/wiki/OnePlus_6_(oneplus-enchilada)

### README.md 内容（解码后）

```markdown
# postmarketOS for the OnePlus 6/T

# This installation method is OUT OF DATE AND WILL NO LONGER BE RECOMMENDED. Please see the list of supported installation methods on the wiki
https://wiki.postmarketos.org/wiki/OnePlus_6_(oneplus-enchilada)

This flashable installer uses a custom initramfs, meaning any kernel updates after install WILL soft brick your device as the ramdisk is replaced. Please reach out if you're interested in managing the installer and ramdisk capabilities (booting from an image) into the postmarketOS ramdisk!

---

[postmarketOS](https://postmarketos.org) aims to be a completely free and Open Source Linux distro for mobile phones, here I release custom TWPR compatible zips for the OnePlus 6 and 6T to simplify the installation procedure and let you check out Mainline Linux on your phone!

If you want to stay up with the latest development, follow me on Twitter, and join the Discord!

[![Twitter Badge](https://img.shields.io/badge/Twitter-1ca0f1?style=flat-square&labelColor=%40calebccff&labelColor=1ca0f1&logo=twitter&logoColor=white&link=https://twitter.com/calebccff)](https://twitter.com/calebccff) [![Discord](https://img.shields.io/badge/Discord-7289da)](https://discord.gg/haV9Ga)

The discord is also bridged [to Telegram](https://t.me/linuxoneplus) and [to Matrix](https://matrix.to.com/#/clopen-general:community.tech).

## Pictures

|<img src="images/appscreenshot.jpg" width="75%">|<img src="images/neofetch.jpg" width="75%">|
|:-:|:-:|
|*App list*|*Neofetch output*|

## Important Info

BEFORE downloading and flashing please READ THE REST OF THIS README, also acquainted with [the wiki page](https://wiki.postmarketos.org/wiki/OnePlus_6_(oneplus-enchilada)), specifically note the available features table and the issues section.

**These builds are for testing and development and are not expected to be stable**

## Instructions

## Download

Check out the [releases tab](https://github.com/calebccf/pmos-oneplus6/releases).

## Install

You can rename the file to pick which slot to flash to, find out your currently active slot by checking the reboot menu in TWRP. It is recommended to flash to the inactive slot so that you can return to Android by simply switching back. Available slots are: ["a", "b"].

Simply boot into TWRP, flash the zip and reboot, the installer will automatically put you on the right slot and set everything up.

> **PLEASE NOTE:** You can NOT install TWRP or any custom recovery on the slot running postmarketOS, it will not boot due to modifications made by the installer, it will also break postmarketOS.

## Login

Username: `user`
Password: `a1234`

You can change both of these in settings. Note that you won't be able to unlock the device if you use a non-numeric password.

## postmarketOS

In the future, I hope to be able to make use of the postmarketOS setup which will allow you to pick your own username, password, however it currently doesn't support Android devices, we're hoping to change this in the future [(#3)](https://gitlab.com/sdm845-mainline/pmos-installer/-/issues/3).

## Known issues

* The gnome software center isn't able to fetch a list of available packages, however it's still possible to search for and install software, e.g. search "2048" for a bit of fun :)

* The device may occasionally boot into crashdump mode shortly before / after reaching UI, this is a known issue.

## Switching back

When you're done playing with postmarketOS, switch back to Android by rebooting into bootloader and running the following command on your PC:
```bash
fastboot --set-active=SLOT
```

Where SLOT is the slot with android installed, that will be the opposite slot to the one in the zip file name.

If your Android is **rooted** you can install the [Switch My Slot](https://github.com/gibcheesepuffs/Switch-My-Slot-Android) app to switch to postmarketOS without PC.

If you wish to keep your postmarketOS install, make sure not to flash any updates from Android as they will overwrite it.

## Creating an issue

If your issue is with software, i.e. display brightness doesn't work, you must fetch full output logs by running the following command, and attach them to the issue via pastebin or a similar service.

Run the following with your device connected via USB:
```bash
ssh user@172.16.42.1 dmesg > dmesg.log
```

The command will create a file called `dmesg.log` on your host which you should upload to a pastebin service when opening an issue there.

If you have an issue that prevents postmarketOS from booting (nothing appears on our host), please include a detailed description of the problem, if I can't understand or reproduce the problem then I won't be able to help. I may ignore issues that do not meet these requirements.
```

### 关键信息

1. **状态：** 已过时（OUT OF DATE）
2. **推荐：** 查看 wiki 页面获取最新的安装方法
3. **内核：** 使用 mainline Linux 内核
4. **问题：**
   - 内核更新后会导致设备变砖（因为 ramdisk 被替换）
   - GNOME 软件中心无法获取软件包列表
   - 设备偶尔会进入 crashdump 模式

### 其他 PostmarketOS 内核仓库

通过 GitHub API 搜索，找到了以下 PostmarketOS 内核仓库：

1. **kcxt/pmos-oneplus6**（已归档）
   - OnePlus 6/6T
   - 使用 mainline Linux 内核
   - 已过时

2. **Empyreal96/linux-sony-hollyss-packaged-kernels-extra**
   - Sony Xperia M5
   - 使用 Linux 内核

3. **LinuxForExynos/pmos-samsung-on7xelte**
   - Samsung Galaxy A51
   - 设备树

4. **casept/linux-samsung-smartwatch**
   - Samsung Gear smartwatches
   - 使用 mainline Linux 内核

5. **ivon852/sony-pdx206-mainline**
   - Sony Xperia 5 II
   - 使用 mainline Linux 内核

### 结论

1. **PostmarketOS 对 OnePlus 6/6T 的支持：**
   - 有 mainline Linux 内核支持
   - 但是已经过时，不再推荐使用
   - 需要查看 wiki 页面获取最新的安装方法

2. **内核版本：**
   - 使用 mainline Linux 内核（不是 Android 内核）
   - 内核版本可能较新（5.x 或 6.x）

3. **问题：**
   - 内核更新后会导致设备变砖
   - 某些功能可能不支持（如 GNOME 软件中心）
   - 设备稳定性可能有问题

4. **建议：**
   - 查看 PostmarketOS wiki 页面获取最新的安装方法
   - 考虑使用其他发行版的内核（如 Ubuntu Touch）
   - 或者继续使用 Android 内核（当前方案）

### 下一步

1. 查看 PostmarketOS wiki 页面获取最新的安装方法
2. 调研 Ubuntu Touch 的内核
3. 选择一个方案开始实施
