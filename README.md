[简体中文](README.md) · [English](README.en.md)

<div align="center">

# HyprSequoia

一套为 Arch Linux 打造的原创、模块化 Hyprland 桌面体验，视觉设计灵感来自 macOS Tahoe。

</div>

HyprSequoia 是一个可长期维护的完整桌面项目，而不是个人配置文件的简单集合。项目提供交互式安装、配置备份、失败回滚、更新和恢复工具，帮助 Arch Linux、KDE 迁移用户以及 Linux 新手快速搭建一套稳定、清晰且易于维护的 Wayland 桌面。

> **当前状态：v0.1 基础版本。** Hyprland 会话、安装器、备份与恢复、Tahoe 顶部菜单栏、常驻 Dock、Spotlight、统一控制中心、系统设置入口、通知中心、明暗主题、锁屏、壁纸及日常硬件集成已经可用。完整 Dock 拖动排序和启动弹跳在可选 Rust 后端中可用；图形化安装器仍在路线图中。

## 功能概览

- 模块化 Hyprland 配置，输入、外观、窗口规则、快捷键和自启动相互独立
- Tahoe 风格透明顶部菜单栏，包含网络、蓝牙、音量、电池、时钟、通知和控制中心入口
- Tahoe Liquid Glass 风格 Spotlight：应用、文件、计算器、单位/货币换算、剪贴板、Emoji、最近文件、设置和快捷操作
- SwayNC 控制中心与通知中心，集成 Wi-Fi、蓝牙、明暗模式、Night Shift、亮度、音量、媒体和日历控件
- 底部常驻 Tahoe Dock：运行指示、收藏应用、最近应用和多显示器支持
- 统一的 HyprSequoia 系统设置入口和跨组件明暗主题控制
- Hyprlock 模糊锁屏和 Hypridle 自动锁定策略
- PipeWire 音频、NetworkManager、蓝牙、亮度及截图集成
- 完整安装、最小安装、中文环境以及 NVIDIA、AMD、Intel 硬件配置
- 安装前自动备份，部署失败自动恢复
- 可选的 KDE Plasma 安全迁移工具，始终保留 SDDM

## 使用方法

### 1. 安装前准备

请在已更新的 Arch Linux 系统上操作，并确认：

- 当前使用普通用户登录，不要直接使用 `root`
- 当前用户能够通过 `sudo` 执行管理员操作
- 网络连接正常
- 已安装 `git`：`sudo pacman -S --needed git`
- Walker 与部分主题组件来自 AUR。可以预先安装 `yay` 或 `paru`；若两者都不存在，安装器会明确询问是否从 AUR 构建 `yay-bin`，拒绝后不会下载或执行任何第三方 PKGBUILD

建议先更新系统并重启：

```bash
sudo pacman -Syu
reboot
```

### 2. 下载并启动安装器

```bash
git clone https://github.com/Rainlinbell/HyprSequoia.git
cd HyprSequoia
./install.sh
```

安装器会显示以下选项：

| 选项 | 用途 |
|---|---|
| Full Install | 安装完整桌面和常用图形工具，推荐大多数用户选择 |
| Minimal Install | 只安装核心 Hyprland 桌面组件 |
| Chinese Environment | 完整安装并配置 Fcitx5、Rime 和 Noto CJK 字体 |
| NVIDIA / AMD / Intel | 手动指定显卡配置；NVIDIA 首次安装会询问 open/proprietary DKMS 驱动 |
| Remove KDE Plasma | 安装后进入单独确认的 KDE 迁移流程，并保留 SDDM |
| Restore Backup | 恢复最近一次安装前的配置备份 |

安装过程会先通过 `pacman -Syu` 完成 Arch 全系统升级并安装软件包，再备份项目管理范围内的 `~/.config` 配置，然后部署并校验 Hyprland、Waybar、Dock 与 SwayNC 配置，最后启用 NetworkManager 和蓝牙服务。如果配置部署或校验失败，安装器会自动恢复本次安装前的配置。

### 3. 进入 HyprSequoia 桌面

安装完成后：

1. 注销当前桌面会话。
2. 在 SDDM 登录界面的会话菜单中选择 **HyprSequoia**（缺少 `uwsm` 时不要选择 UWSM-managed 条目）。
3. 使用原有账号登录。
4. 首次进入后按 `Super` + `Space` 测试 Walker，点击顶部菜单栏的网络、蓝牙、音量和通知图标确认对应组件工作正常。

安装器不会默认卸载 KDE。建议先保留 KDE 作为备用会话，确认 HyprSequoia 能满足日常使用后，再运行 `./uninstall-kde.sh`。

### 4. 常用快捷键

| 操作 | 快捷键 |
|---|---|
| 打开 Spotlight / 应用搜索 | `Super` + `Space` |
| Spotlight 最近文件 | `Super` + `Shift` + `Space` |
| Spotlight 设置搜索 | `Super` + `Shift` + `S` |
| Spotlight 快捷操作 | `Super` + `Shift` + `A` |
| 打开终端 | `Super` + `Enter` |
| 打开文件管理器 | `Super` + `E` |
| 打开系统设置 | `Super` + `,` |
| 打开控制中心 | `Super` + `Shift` + `C` |
| 锁定屏幕 | `Super` + `L` |
| 关闭当前窗口 | `Super` + `Q` |
| 切换全屏 | `Super` + `F` |
| 切换浮动窗口 | `Super` + `V` |
| 显示 Dock | `Super` + `B` |
| 切换到工作区 1–4 | `Super` + `1`–`4` |
| 将窗口移动到工作区 1–4 | `Super` + `Shift` + `1`–`4` |
| 区域截图 | `Print` |
| 全屏截图 | `Shift` + `Print` |

截图会保存到 `~/Pictures/Screenshots` 并自动复制到剪贴板。键盘媒体键和亮度键分别通过 PipeWire 与 `brightnessctl` 工作。

### 5. 更新

在仓库目录中运行：

```bash
cd HyprSequoia
./update.sh
```

更新工具要求 Git 工作区没有未提交修改，并只接受快进更新。若首次 HTTPS 拉取遇到临时 `SSL_read` 中断，会在保持证书验证的前提下使用 HTTP/1.1 重试一次。拉取新版本后会重新进入交互式安装流程，在覆盖配置前创建新的备份。

### 6. 恢复配置

如果新配置不符合预期，可在仓库目录运行：

```bash
./restore.sh
```

确认后，工具会删除安装清单中记录的托管文件，并恢复最近一次安装前备份。它不会卸载软件包、关闭系统服务，也不会删除不在安装清单中的个人文件。

日志、备份和安装清单位于：

```text
~/.local/state/hyprsequoia/
```

进一步说明请参阅[安装、更新与恢复文档](docs/LIFECYCLE.md)。

### Spotlight

按 `Super + Space` 打开居中的 Walker Spotlight。输入 `/` 搜索文件、`=` 进行
计算以及单位/货币换算、`:` 搜索剪贴板、`,` 搜索 Emoji 和符号、`.` 搜索
Unicode、`;` 切换搜索提供器。Walker 以后台服务方式预热，Elephant 根据
使用历史进行搜索排序；完整安装仅安装这些功能直接需要的 provider。主题、
键盘操作和排障说明请参阅 [Spotlight 文档](docs/SPOTLIGHT.md)。安装器只安装这些
已声明功能直接使用的 Elephant provider，不安装全量 provider 包。

### Dock

安装后 Dock 会以常驻模式随 Hyprland 会话自动启动，不再使用底部自动隐藏
热点。若系统中存在 Rust 版 `nwg-dock`，HyprSequoia 会启用完整的原生 Dock
（拖动排序和启动弹跳）；否则会自动使用 Go 版或 Waybar 轻量回退实现。
详见[Dock 文档](docs/DOCK.md)和[外观文档](docs/APPEARANCE.md)。

## 项目结构

- `configs/hypr/conf.d/`：独立的 Hyprland 功能模块
- `configs/sddm/`：通过 `start-hyprland` 启动的 HyprSequoia 会话入口
- `configs/{waybar,kitty,walker,swaync}/`：桌面应用配置
- `configs/applications/`：HyprSequoia 桌面应用入口
- `configs/dock/`：原生优先的底部 Dock 与 Waybar 回退配置
- `scripts/lib/`：安装器共享函数和软件包逻辑
- `scripts/bin/`：安装到 `~/.local/bin` 的运行时工具
- `themes/` 和 `wallpapers/`：项目视觉资源与主题变体
- `docs/`：架构、生命周期、故障排查和路线图

参与开发前请阅读[架构说明](docs/ARCHITECTURE.md)和[贡献指南](CONTRIBUTING.md)。

## 故障排查

### 登录后黑屏并返回 SDDM

这通常表示 Hyprland 在创建会话时退出，而不是 Waybar 或 Dock 单独故障。按 `Ctrl` + `Alt` + `F3` 进入 TTY，登录同一账号，然后更新并重新运行安装器：

```bash
cd ~/HyprSequoia   # 如果仓库不在这里，请换成实际路径
git pull --ff-only
./install.sh
```

本版本已迁移 Hyprland 0.53+ 的窗口规则、图层规则和手势语法，添加通用显示器兜底，并在安装结束前运行 `Hyprland --verify-config`。安装器还会创建明确调用 `start-hyprland` 的 **HyprSequoia** 会话条目，并提示不要误选缺少 `uwsm` 的 UWSM-managed 条目。如果是 NVIDIA，安装完成后必须先重启。

如果仍然返回 SDDM，在 TTY 运行：

```bash
~/.local/bin/hyprsequoia-diagnose
cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null
```

诊断报告会保存在 `~/.local/state/hyprsequoia/logs/diagnose-*.log`。请在提交问题前检查其中是否含个人信息。

### 组件故障

首先查看 `~/.local/state/hyprsequoia/logs` 中最新的安装和会话日志，然后运行：

```bash
hyprctl systeminfo
journalctl --user -b
```

如果只是菜单栏或通知中心异常，优先单独重启对应组件。例如：

```bash
killall waybar
waybar
```

常见的 SDDM 登录返回、NVIDIA 黑屏、屏幕共享以及中文输入问题，请参阅[故障排查文档](docs/TROUBLESHOOTING.md)。

## 常见问题

**这是 WhiteSur 或其他 dotfiles 项目的分支吗？**

不是。项目架构、配置、脚本和内置图稿均为原创设计。可选第三方主题遵循各自的上游许可证，不会作为本项目资源直接复制。

**支持 NVIDIA 吗？**

支持。安装器会保留已安装的 NVIDIA 驱动；全新配置会让用户选择 `nvidia-open-dkms` 或 `nvidia-dkms`，同时安装匹配的标准 Arch 内核头文件、`nvidia-utils` 和 `egl-wayland`。RTX 50 系列必须使用 open 内核模块，RTX/GTX 16 系列及更新型号通常也推荐 open 模块；旧型号请选择 proprietary DKMS。驱动安装后需要重启。

**可以继续保留 KDE 吗？**

可以，而且这是推荐的迁移方式。只有明确选择迁移功能或手动运行 `uninstall-kde.sh` 才会进入 Plasma 移除流程。

**为什么可能需要 yay？**

Walker、Elephant provider 和部分主题组件可能需要从 AUR 安装。安装器会先检查
Arch 官方仓库，并优先使用已有的 `yay` 或 `paru`。如果两者都不存在，它会显示
`yay-bin` 的 AUR 地址并请求确认；只有明确回答 `y` 才会安装 `base-devel`、克隆
PKGBUILD 并运行 `makepkg`，不会静默引导 AUR 助手。

## 路线图与版本

HyprSequoia 遵循[语义化版本](https://semver.org/lang/zh-CN/)。完整计划请参阅[路线图](docs/ROADMAP.md)与[更新日志](CHANGELOG.md)。1.0 之前的版本可能会调整配置接口。

## 贡献与许可证

欢迎根据[贡献指南](CONTRIBUTING.md)提交改进。参与社区前请阅读[行为准则](CODE_OF_CONDUCT.md)。HyprSequoia 使用 [MIT 许可证](LICENSE)。
