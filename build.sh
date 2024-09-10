#!/bin/bash


APP_NAME="Transput"
APP_PATH="build/Release/Transput.app"
INSTALL_LOCATION="$HOME/Library/Input Methods"
PKG_NAME="$APP_NAME.pkg"

xcodebuild -configuration Release -arch arm64
# 创建 PKG 文件
pkgbuild --root "$APP_PATH" \
         --install-location "$INSTALL_LOCATION/$APP_NAME.app" \
         --identifier "com.janlely.inputmethod.${APP_NAME}" \
         --version "1.0" \
         "$PKG_NAME"

echo "PKG 文件已创建：$PKG_NAME"
