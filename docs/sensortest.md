# JT600 SensorTest

SensorTest 是用于 JT600 人工验收的 Android 应用，包名为 `com.jt600.sensortest`，公开版本为 `1.1`（`versionCode=2`）。

## 能测试什么

- 动态列出设备实际提供的传感器；
- 光传感器：观察 lux 随遮挡变化；
- 距离传感器：观察近/远两档变化；
- 头顶、左耳、右耳三个独立按键的真实 DOWN/UP 事件；
- 屏幕触摸事件；
- 电池电量、电压、温度和电流字段（本机内核未提供的字段可能显示 0）；
- LED 点亮、关闭和跑马灯；
- 电机连接、状态、回中、左右端点和指定角度。

LED 和电机由目标系统的 JT600 服务提供。开发者可以自由修改源码并使用 [Sign-JT600SensorTest.ps1](../tools/flash/Sign-JT600SensorTest.ps1) 签名自己的 APK；签名材料放在 `firmware-package\signing\`，不受仓库工作流限制。使用匹配系统 platform certificate 签出的 APK 即可调用 `CONTROL_LEDS` 和 `CONTROL_MOTOR`。

## 建议验收顺序

打开应用后依次检查传感器总览、光、距离、三个按键、触摸和电池。LED 和电机测试必须有人监督；电机异常时立即使用停止按钮，不要把手伸入运动机构。

## 安装

仓库中的 `artifacts/JT600-SensorTest-1.1-platform.apk` 是预构建 APK，不是刷机包。安装前核对 [artifacts/SHA256SUMS.txt](../artifacts/SHA256SUMS.txt)。用户可在 Android 设置中卸载它；卸载不会写入系统分区。
