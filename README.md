<p align="center">
  <img src="./FilePop/Assets.xcassets/AppIcon.appiconset/FilePopIcon-256.png" width="128" alt="FilePop 图标" />
</p>

<h1 align="center">FilePop</h1>

<p align="center">
  轻量、原生、克制的 macOS Finder 右键增强工具
</p>

<p align="center">
  <a href="https://github.com/LQF-dev/FilePop/releases/download/v1.0-1/FilePop-1.0-1-macOS.dmg">
    <strong>下载 FilePop 1.0-1</strong>
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

## 设计原则

FilePop 的设计原则是克制和原生。

- 只保留真正高频的功能
- 不制造臃肿的右键菜单
- 不弹出多余的复杂界面
- 不破坏 Finder 原有操作习惯
- 尽量让每个操作都发生在当前文件夹上下文中
