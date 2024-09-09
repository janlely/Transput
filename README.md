# Transput

一个支持AI翻译的拼音输入法，基础框架fork自[Typut](https://github.com/ensan-hcl/Typut)
引擎使用rime,引擎配置相关代码从[squirrel](https://github.com/rime/squirrel)copy而来



## Working Environment

Checked in March 2024.
* macOS 14.3
* Swift 5.10
* Xcode 15.3
* Arch arm64

## 使用指南

* AI翻译
![image](./show.gif)

## 快捷键

| 功能 | 描述 | 快捷键 |
| :-----: |  :----: | :----: |
| 中英切换 | 在输入法内切换中英文，便于翻译前的中英混合输入 | `Shift` |
| 翻译开关 | 开启/关闭翻译功能，方便非翻译场景下使用 | `Ctrl_t` or `/s` |
| 翻译        |  将当前的文本进行AI翻译后自动提交  |  `Ctrl_Enter` or `/t` |
| 提交文本 |  无需翻译，直接提交当前文本  | `Enter`  or  `/g` |
| 粘贴文本 |  从系统剪切板粘贴内容 | `/v` |





## 本地安装

* build
```bash

./install.sh
```

* 注销当前用户

* 在系统输入法设置中添加Transput


## 切换输入方案

schema目录中有wubi和piny拼音方案,分别算来自[极点五笔](https://github.com/KyleBing/rime-wubi86-jidian)和[雾凇拼音](https://github.com/iDvel/rime-ice)

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
