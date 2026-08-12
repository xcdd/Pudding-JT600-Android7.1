# Pudding JT600 Android 7.1

这是 JT600 Android 7.1 项目的公开说明和 SensorTest 源码仓库。

## 先看这里

- [新手刷机说明](docs/flashing-guide.md)
- [工具目录索引](tools/README.md)
- [安装 Rockchip USB 驱动](tools/flash/00-install-drivers.cmd)
- [原厂设备备份脚本](tools/flash/00-export-original-jt600.cmd)
- [一键原厂刷写入口](tools/flash/Run-JT600Flash-Factory.cmd)
- [定制系统更新入口](tools/flash/Run-JT600Flash-Update.cmd)
- [恢复写后验收](tools/flash/Resume-JT600Verification.cmd)
- [SensorTest 使用与测试](docs/sensortest.md)
- [SensorTest 构建说明](docs/build.md)
- [第三方声明](NOTICE.md)
- [发布记录](CHANGELOG.md)

### 重要边界

刷机文件应放在仓库根目录的 `firmware-package\` 目录中。这里没有固件下载地址；没有与你的设备和版本明确匹配的刷机文件时，请停止操作。

刷机可能使设备无法启动、清除用户数据或造成硬件功能异常。完全没有刷机经验时，只阅读新手说明并请有经验的人在现场操作。

## 许可证

本项目原创的源代码和说明文档按 [CC BY-NC-SA 4.0](LICENSE) 发布：必须署名、禁止商业用途，改作必须使用相同许可证。第三方内容仍受其原许可证约束，详见 [NOTICE.md](NOTICE.md)。
