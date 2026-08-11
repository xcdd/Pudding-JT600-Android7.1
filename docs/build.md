# SensorTest 构建

## 环境

- JDK 17；
- Gradle 7.5；
- Android SDK Platform 33；
- Android build-tools 33.0.2；
- Android Gradle Plugin 7.4.2；
- Android 7.1/ARMv7 目标设备用于运行验收。

源码和构建缓存应放在 Linux/WSL 的 ext4 文件系统中。路径包含中文时，使用 ASCII 工作路径。

## 构建命令

在仓库根目录执行：

```sh
gradle -p apps :sensortest:assembleDebug
gradle -p apps :sensortest:assembleRelease
```

APK 输出在 `apps/sensortest/build/outputs/apk/`。构建后用 `aapt dump badging` 核对包名 `com.jt600.sensortest`、`versionCode=2` 和 `versionName=1.1`。

`targetSdk` 固定为 25，以保持 Android 7.1 上已经验证的权限和系统服务行为。该应用不面向 Google Play，因此构建配置只关闭现代 Lint 中不适用的 `ExpiredTargetSdkVersion` 上架检查。

源码构建会生成可运行的 unsigned/release APK。要让自己的修改版使用 JT600 LED/电机服务，把本地 platform key 放进 `firmware-package\signing\`，然后运行：

```powershell
powershell -File tools\flash\Sign-JT600SensorTest.ps1 `
  -UnsignedApk apps\sensortest\build\outputs\apk\release\sensortest-release-unsigned.apk `
  -ApkSignerPath C:\path\to\Android\Sdk\build-tools\33.0.2\apksigner.bat
```

这只是 Android 7.1 的 development/test platform certificate 能力匹配，不是本项目对开发者的使用限制。开发者可以自由修改、签名和使用 LED/电机；签名材料属于本地 `firmware-package`，不提交到 GitHub。
