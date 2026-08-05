<p align="center">
  <img src="./FilePop/Assets.xcassets/AppIcon.appiconset/FilePopIcon-256.png" width="128" alt="FilePop 图标" />
</p>

<h1 align="center">FilePop</h1>

<p align="center">
  轻量、原生、克制的 macOS Finder 右键增强工具
</p>

<p align="center">
  <img alt="小红书 @6975527999" src="https://img.shields.io/badge/%E5%B0%8F%E7%BA%A2%E4%B9%A6-%406975527999-ff2442?style=flat-square&amp;labelColor=333333" />
</p>

<p align="center">
  <a href="https://github.com/LQF-dev/FilePop/releases/download/v1.1.0/FilePop-1.1.0-macOS.dmg">
    <strong>下载 FilePop 1.1.0</strong>
  </a>
</p>

---

## 项目简介

FilePop 是一个专注于 Finder 当前文件夹的 macOS 右键增强工具。

它不会弹出额外窗口，也不会重新打开一个新的目录界面，而是把常用操作自然地嵌入到 Finder 原生右键菜单中。

目前只保留三个最常用的能力：

- 新建文件
- 复制当前文件夹路径
- 在当前文件夹打开终端

## 为什么做这个项目

市面上已经有不少右键增强工具，但实际使用时经常会遇到这些问题：

- 基础功能需要付费
- 右键体验不够原生，经常需要额外窗口或独立界面
- 没有真正基于当前 Finder 文件夹上下文工作
- 功能过多，菜单臃肿，反而影响效率和观感

FilePop 想解决的就是这些问题。

它不追求大而全，只希望把最常用的 Finder 操作做得更自然、更干净、更贴近系统原生体验。

## 下载

- 最新版本：FilePop 1.1.0
- dmg下载：[FilePop-1.1.0-macOS.dmg](https://github.com/LQF-dev/FilePop/releases/download/v1.1.0/FilePop-1.1.0-macOS.dmg)

## 更新记录

### 1.1.0（2026-08-05）

- 在桌面新建文件时不再弹出 Finder 文件夹窗口，文件会直接出现在桌面并进入重命名。
- 移除桌面新建流程中的模拟鼠标点击，避免屏幕闪动。
- 修复 Word、Excel 和 PowerPoint 文件在桌面重命名后的内容与图标识别。
- 修复 PowerPoint 模板结构不完整导致 PowerPoint、WPS 无法正常打开的问题。

### 1.0.2-3（2026-07-03）

- 新增外置磁盘增强开关，默认关闭；开启后可在外置硬盘、SD 卡等外置卷中使用右键新建。
- 外置磁盘增强开启时，Finder 侧边栏磁盘图标可能被 macOS 替换，属于 Finder Sync 扩展机制限制。
- 修复扩展监听目录在设置变更和外置卷挂载/卸载后不会及时刷新的问题。

### 1.0.1-2（2026-06-30）

- 修复重复点击设置后，状态栏应用闪退的问题。

### 1.0.1（2026-06-26）

- 初始发布版本。
- 支持 Finder 右键新建文件、复制当前文件夹路径、在当前文件夹打开终端。

## 核心能力

### 新建文件

支持两种模式：

- 手动后缀模式：输入完整文件名，例如 `note.md`、`todo.txt`
- 模板选择模式：从预设模板中快速创建文件，例如 Markdown、Word、Excel 等

### 复制文件夹路径

在 Finder 当前目录右键，即可复制当前文件夹路径，方便粘贴到终端、编辑器、脚本或其他工具中。

### 打开终端

在 Finder 当前目录右键，即可直接从该目录打开终端，减少手动 `cd` 的重复操作。

## 权限设置

首次使用 FilePop 前，请按以下步骤完成权限授权：

打开 系统设置 > 隐私与安全性 > 辅助功能，点击「+」添加并允许 FilePop.app。

打开 系统设置 > 登录项与扩展 > Finder 扩展，确保 FilePop 开关处于开启状态。

完成上述设置后，即可在 Finder 中正常使用 FilePop 的右键增强功能。

## 支持范围

- 支持系统：macOS 13.0 到 macOS Tahoe 26 正式版系列（当前 Apple 公开更新到 macOS 26.5.2）
- 当前发布环境：Xcode 26.6，macOS 26.5 SDK
- 暂不声明支持：macOS 26.6 beta、macOS 27 beta

FilePop 依赖 macOS Finder Sync 扩展能力，目前主要面向普通本地文件夹中的 Finder 右键菜单增强。

## 文件夹生效说明

FilePop 默认仅增强当前 macOS 登录用户目录下的普通本地文件夹，例如：

```text
/Users/当前用户名/...
```

默认不增强外置硬盘、SD 卡等外置卷中的文件夹。

如需在外置硬盘、SD 卡中使用右键新建，可以在 FilePop 设置中开启「外置磁盘增强」。开启后，Finder 侧边栏中的磁盘图标可能被 macOS 替换：

- macOS 15 上可能显示为系统默认图标
- macOS 26 上可能显示为 FilePop 图标

这是 Finder Sync 扩展和 Finder 侧边栏图标刷新机制导致的系统层行为。不同 macOS 版本的 Finder 缓存和刷新逻辑不同，因此会看到不同的图标表现；当前应用侧无法可靠规避。

FilePop 不支持在 iCloud 云盘、OneDrive、Dropbox 等云盘目录中稳定显示 Finder 右键增强菜单。

原因是这些目录通常由 Apple File Provider 机制接入 Finder，并由对应云盘客户端管理。例如 iCloud 云盘由 Apple 系统服务管理，OneDrive 目录由 Microsoft OneDrive 管理，Dropbox 目录由 Dropbox 管理。它们会接管自己的 Finder 集成、文件状态和上下文菜单。

FilePop 是第三方 Finder Sync 扩展，不能稳定地把菜单注入到其他应用管理的 File Provider 云盘目录中。因此，云盘目录中的右键菜单是否出现 FilePop，不作为当前版本的支持范围。

## 设计原则

FilePop 的设计原则是克制和原生。

- 只保留真正高频的功能
- 不制造臃肿的右键菜单
- 不弹出多余的复杂界面
- 不破坏 Finder 原有操作习惯
- 尽量让每个操作都发生在当前文件夹上下文中
