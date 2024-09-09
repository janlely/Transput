#!/bin/bash

xcodebuild -configuration Release -arch arm64

cp -r build/Release/Transput.app ~/Library/Input\ Methods/

if [ $1 = "wubi" ]; then
    cp -r schema/Wubi ~/Library/Transput
elif [ $1 = "pinyin" ]; then
    cp -r schema/Pinyin ~/Library/Transput
else
    echo "Usage: $0 wubi/pinyin"
fi
