#!/bin/sh
set -e
xctool -project genstrings2.xcodeproj -scheme "Static Library" test -arch x86_64 ONLY_ACTIVE_ARCH=NO
appledoc -o /tmp .
