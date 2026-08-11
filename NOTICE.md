# Third-party notices

本仓库的 JT600 SensorTest 业务代码和说明由本项目作者发布。以下内容不是本项目原创内容，继续受其原许可证约束：

- Android SDK/API 及 Android framework 的公共接口：按 Android SDK 和 AOSP 的适用许可证使用；
- `apps/sensortest/src/main/java/android/app/ActivityThread.java` 与 `ContextImpl.java` 是仅用于编译反射调用的最小 stub，不包含 Android framework 实现；
- `apps/sensortest/src/main/java/com/jt600/motor` 与 `com/jt600/led` 是 JT600 系统服务的接口描述，实际系统服务和签名材料不在本仓库。

本仓库不重新分发 Android SDK、系统镜像、Loader、设备固件或校准数据。开发用签名材料放在本地 `firmware-package\signing\`。第三方商标和设备名称仍归其权利人所有。
