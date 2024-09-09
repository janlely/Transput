# Transput

一个支持AI翻译的拼音输入法，基础框架fork自[Typut](https://github.com/ensan-hcl/Typut)

目前只支持全拼, 词库来自[这里](https://code.google.com/archive/p/hslinuxextra/downloads)


## Working Environment

Checked in March 2024.
* macOS 14.3
* Swift 5.10
* Xcode 15.3

## 使用指南

* AI翻译
![image](./show.gif)

* 使用`shift`在输入法内切换中英文,方便在翻译之前输入中英混合的内容

* 使用`ctrl+t`或者`/s`开启/关闭AI翻译(需先设置apiKey)

* 输入法菜单中可以设置AI翻译的apikey

* AI翻译模式下`Ctrl + Enter`或者`/t`触发翻译按钮点击

* AI翻译模式下Enter或者`/g`触发直接提交文本

* AI翻译模式下`/v`从系统剪切板粘贴文本

## 本地安装

* build
```bash

xcodebuild

cp -r build/Release/Transput.app ~/Library/Input\ Methods/
```

* 注销当前用户

* 在系统输入法设置中添加Transput


