# 川普输入法（Transput） - 支持 AI 翻译的智能输入法

## 项目简介

[Transput](https://transput.me) 是一款专为经常在中英文环境下工作的用户打造的智能输入法。它基于 Rime 输入法框架，集成了先进的 AI 翻译功能，旨在为用户提供流畅高效的双语输入和翻译体验。无论是在与外籍同事沟通、阅读英文文献、还是撰写中英文邮件时，Transput 都能帮助你轻松应对。

## 功能亮点

- **AI 翻译**：内置通义千问和 GPT-3.5-Turbo 两种先进的 AI 翻译模型，一键翻译。
- **双语输入**：支持中英文混合输入，输入法会自动识别语言，让你无缝切换。
- **快捷键操作**：提供一系列直观的快捷键，让你掌控全局，高效输入。
- **多种输入方案**：内置五笔、拼音等多种输入方案，用户可根据习惯自由切换。
- **灵活控制翻译开关**：使用/s可以控制翻译功能的开关
- **自定义API接口和提示词**：提供配置界面自定义api地址和翻译提示词


## 界面预览

![主界面](https://i.postimg.cc/XvXvk6s8/output.gif)

* 主界面：简洁美观的输入界面，支持中英文混合输入
* 翻译功能：一键触发 AI 翻译，实现中英翻译
* 输入方案切换：轻松切换五笔、拼音等多种输入方案

## 安装指南

### 从源码编译安装

1. 克隆本仓库：`git clone https://github.com/yourusername/transput.git`
2. 进入项目目录：`cd transput`
3. 编译项目：`xcodebuild -configuration Release -arch arm64`
4. 拷贝编译好的应用：`cp -r build/Release/Transput.app ~/Library/Input\ Methods/`
5. 注销当前用户，重新登录
6. 在系统输入法设置中添加 Transput

### 下载安装包

我们为主流系统打包了安装包，可以从以下链接下载：

- [macOS-arm64](https://github.com/janlely/Transput/releases/download/1.0.0/Transput.pkg)

下载完成后，双击安装包，按照提示完成安装即可。

## 使用教程

### 快捷键

| 功能 | 描述 | 快捷键 |
| :-----: | :----: | :----: |
| 中英切换 | 在输入法内切换中英文，便于翻译前的中英混合输入 | `Shift` |
| 翻译开关 | 开启/关闭翻译功能，方便非翻译场景下使用(需要先设置apikey) | `Ctrl_t` 或 `/s` |
| 翻译 | 将当前的文本进行AI翻译后自动提交 | `Ctrl_Enter` 或 `/t` |  
| 提交文本 | 无需翻译，直接提交当前文本 | `Enter` 或 `/g` |
| 粘贴文本 | 从系统剪切板粘贴内容 | `/v` |

## 切换输入方案

schema目录中有五笔和拼音方案,分别算来自[极点五笔](https://github.com/KyleBing/rime-wubi86-jidian)和[雾凇拼音](https://github.com/iDvel/rime-ice)

* 复制方案文件

```bash

rm -rf ~/Library/Transput

# 五笔
cp -r schema/Wubi ~/Library/Transput

# 拼音
cp -r schema/Pinyin ~/Library/Transput

```

* 重载输入法

点击输入法菜单中的`Deploy`按钮,需要等待一会儿

## 感谢

Transput 的诞生离不开以下开源项目：

- [Rime](https://rime.im/)：中州韵输入法引擎
- [Typut](https://github.com/ensan-hcl/Typut)：输入法基础框架
- [Squirrel](https://github.com/rime/squirrel)：输入法 Mac 平台的实现
- [极点五笔](https://github.com/KyleBing/rime-wubi86-jidian)：五笔输入方案
- [雾凇拼音](https://github.com/iDvel/rime-ice)：拼音输入方案

同时也感谢所有为本项目贡献代码的开发者们！

如果你也对输入法开发感兴趣，欢迎参与到 Transput 的开发和完善中来。你可以通过提交 Issue 或 PR 的方式为项目贡献自己的力量。让我们一起打造更智能、更人性化的输入法吧！

## 问题反馈

如果你在使用过程中遇到任何问题，或者有任何建议和想法，欢迎提ISSUE或发送邮件至98705766@qq.com

* 注销当前用户

* 在系统输入法设置中添加Transput


