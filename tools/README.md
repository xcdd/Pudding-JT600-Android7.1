# 工具目录

只需要刷机的用户按顺序使用 `flash` 目录中的入口；不需要阅读脚本源码。

## flash

- `00-install-drivers.cmd`：安装 AndroidTool 使用的 Rockchip USB 驱动；
- `00-export-original-jt600.cmd`：原厂设备首次刷写前导出本机备份；
- `Run-JT600Flash-Factory.cmd`：原厂设备首次完整刷写并扩展可用存储空间；
- `Run-JT600Flash-Update.cmd`：已经刷入定制系统的设备只更新 System；
- `Sign-JT600SensorTest.ps1`：用本地开发签名材料签出可使用 LED/电机服务的 APK；
- `Set-AndroidToolSafeDefault.ps1`：把直接打开 AndroidTool 时的默认配置设为全部写入项未选中；
- 其他 `.ps1` 是上述入口调用的分步骤脚本。

## host

`jt600-host.ps1` 是脚本使用的 USB ADB 调用封装。它只使用调用方传入的 ADB 文件，不要求把 ADB 加入系统 PATH。

固件、AndroidTool、驱动和开发签名材料放在仓库根目录的 `firmware-package\`。
