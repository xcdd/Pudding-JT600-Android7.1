# SensorTest 1.1 prebuilt APK

`JT600-SensorTest-1.1-platform.apk` 是已在 JT600 Android 7.1 系统上验证的预构建 APK，不是刷机包。

- package: `com.jt600.sensortest`
- versionCode: `2`
- versionName: `1.1`
- minSdk: `21`
- targetSdk: `25`
- APK SHA-256: `3F855DEF2D6B5A564EA98377DB2FFAC181770C5F8CC33903EEAFEAD3FE2403D2`
- signer certificate SHA-256: `C8A2E9BCCF597C2FB6DC66BEE293FC13F2FC47EC77BC6B2B0D52C11F51192AB8`

这是使用 JT600 Android 7.1 development/test platform certificate 签出的预构建 APK。开发者可以在本地 `firmware-package\signing\` 使用同一套 development/test key 重新签名自己的修改版，继续调用 LED/电机服务；仓库不限制这种使用。
