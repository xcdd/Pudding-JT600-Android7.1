# JT600 刷机说明（新手版）

## 这件事是什么

“刷机”是把设备中的 Android 系统文件替换成另一套系统文件。过程中设备可能暂时黑屏，也可能清除数据；文件或步骤不匹配时，设备可能无法正常启动。

刷机文件放在仓库根目录的 `firmware-package\` 目录中。没有明确写着与你的 JT600 型号和目标版本匹配的文件时，不要猜测、拼接或借用其他设备的文件。

## 先判断设备状态

- **保留原厂布丁豆豆系统的设备**：走“原厂首次刷写”流程，一次性写入完整系统和扩容配置，使 userdata 达到 5 GiB；不要只写 System。
- **已经刷入我们定制系统的设备**：更新 Kernel 和 System，使两者都达到 V1.2。设备可以在刷写后用 USB ADB 自动验收。

## 固件包和工具目录

把完整的 V1.2 对外版本发布包放入 `firmware-package\jt600-1.2-universal-20260905\`，以发布包自己的 `README.md` 和 `RELEASE-MANIFEST.txt` 为准，不要改文件名或自行替换文件。脚本会快速核对版本组合、文件名、文件大小和写入地址，不会顺序读取大镜像计算哈希。本仓库不提供刷机包，也不说明刷机包的获取位置。

工具目录只需要准备两个文件夹：`AndroidTool-v2.38` 和 `DriverAssistant-v5.14`。`AndroidTool-v2.38\bin` 中配套的是已经验证能识别 JT600 的 ADB 1.0.41；不要换回 AndroidTool 原带的 ADB 1.0.31。脚本会自动使用这两个文件夹，不要求用户逐个寻找工具文件。

打包目录中的 AndroidTool 默认配置是无操作配置：直接打开时所有写入项均未选中。Factory 脚本只验证文件并列出人工填写清单，不会改写 AndroidTool 的分区表。

## 原厂设备首次刷写

1. 只准备一台 JT600，接通稳定电源，拔掉其他同类设备。
2. 双击 `tools\flash\00-install-drivers.cmd`，完成 Rockchip USB 驱动安装。必须先安装驱动，再启动 AndroidTool。
3. 双击 `tools\flash\00-export-original-jt600.cmd`。脚本先启动本地 AndroidTool。
4. AndroidTool 窗口打开后，设备关机，插入 USB，用卡针或回形针按住 microUSB 口旁的小孔。听到电脑的 USB 连接声、并在 AndroidTool 中看到 Loader 后松开。
5. 脚本会依次提示导出本机的 `metadata.img`、`kpanic.img` 和 `parameter-original.bin`。每次按当前提示填写起始地址，点击“导出镜像”；脚本会自动检查大小、保存文件并逐字节核对复制结果，然后提示下一项。三个文件全部完成前不要关闭 AndroidTool。
6. 双击 `tools\flash\Run-JT600Flash-Factory.cmd`。脚本自动使用 `firmware-package\` 中的固件、AndroidTool 和刚才的备份。
7. 脚本验证发布清单中的所有输入，打开 AndroidTool，并在控制台列出本次要填写的项目。AndroidTool 初始为全部未选中，脚本不会生成或加载自定义分区配置。
8. 设备进入 Loader 后，在 AndroidTool 中按控制台清单逐项填写名称、文件路径和起始地址。原厂首次刷写填写以下 7 项：

   | 名称 | 文件 | 起始地址 |
   |---|---|---|
   | Kernel | `firmware-package\jt600-1.2-universal-20260905\K71M147.img` | `0x0000E000` |
   | Boot | `firmware-package\jt600-1.2-universal-20260905\B71M29.img` | `0x00014000` |
   | System | `firmware-package\jt600-1.2-universal-20260905\S71M57.img` | `0x0008A000` |
   | Metadata | `firmware-package\device-backup\metadata.img` | `0x0048A000` |
   | Kpanic | `firmware-package\device-backup\kpanic.img` | `0x0048C000` |
   | Userdata | `firmware-package\jt600-1.2-universal-20260905\userdata-superblock-guard-4m.img` | `0x0048E000` |
   | Parameter | `firmware-package\jt600-1.2-universal-20260905\parameter-expanded-storage.txt` | `0x00000000` |

   只选择这 7 项；Loader、Resource、擦除、低格、校准/NVRAM 和其他未知项目均不选择。点击“执行”，等待下载和校验达到 100%，然后关闭 AndroidTool。
9. 脚本会先启动项目自带 ADB 并检查 Windows 驱动。如果设备已经进入 ADB，直接开始验收；如果驱动缺失，会明确提示重新运行 `tools\flash\00-install-drivers.cmd`，不会假装等待。驱动正常但设备仍在启动时，脚本显示等待秒数和 ADB 状态。原厂首次刷写后 `/data` 一定尚未初始化；不完成这一步设备无法正常启动。脚本确认 userdata 恰为 5 GiB 后会自动初始化 `/data`、重启并继续验收。

如果 AndroidTool 没有留下成功日志，脚本不会停在人工确认界面。它会继续读取设备的 System、Kernel 和 userdata 大小；三项与 V1.2 发布清单完全一致时才自动初始化 `/data`，否则停止并显示不匹配的项目。

如果刷写已经完成，但 CMD 窗口意外关闭，双击 `tools\flash\Resume-JT600Verification.cmd`。它只继续最近一次任务的 ADB 验收和必要的 `/data` 初始化，不会重新打开 AndroidTool，也不会重新刷写。

## 已刷入定制系统的设备

该流程不需要本台设备导出的 `metadata.img`、`kpanic.img` 或原始 Parameter；这些文件只用于原厂首次刷写流程。

1. 双击 `tools\flash\00-install-drivers.cmd`，完成驱动安装。
2. 双击 `tools\flash\Run-JT600Flash-Update.cmd`。脚本会先核对 V1.2 固件，再检查 USB ADB/Loader 状态。
3. 如果设备当前在 Android，脚本会显示设备状态并询问是否自动进入 BL：输入 `Y` 会发送
   `reboot bootloader`，输入 `N` 则由操作者手工进入；脚本会等待并确认唯一 `Rockusb Loader`。
   已经在 BL 的设备直接进入确认步骤；未确认唯一 Loader 前不会启动 AndroidTool。
4. AndroidTool 启动时保持全部写入项未勾选，这是安全默认值，不会自动勾选 System。脚本会在控制台列出
   本次应填写的两行；人工只填写并选择 Kernel 和 System，然后点击“执行”。Loader、Boot、Parameter、
   Metadata、Kpanic、Userdata、Resource、擦除、低格、校准/NVRAM 和其他行均不选择。
5. 控制台应列出 `K71M147.img`（起始地址 `0x0000E000`）和 `S71M57.img`（起始地址 `0x0008A000`）。等待 100% 下载和校验，脚本自动通过 AndroidTool 自带的 USB ADB 做写后检查。

Update 之所以包含 Kernel 和 System 两行，是为了让已经运行旧定制版本的设备同时获得 K147
WiFi 修复和 S57 蓝牙修复；只写 System 只适用于已经单独确认运行 K147 的维护场景，不是公开 Update
流程的默认方式。

## 验收

脚本会显示设备序列号、系统显示版本、Kernel 版本、启动完成状态和 SELinux，并确认 System 为 S71M57、Kernel 为 `#161`。它会确认 System 内含 SensorTest、AIDA64、Chrome、LocalSend、Fcitx5 的投放源；Factory 首次刷写还会等待这五个应用全部成为 `/data/app` 用户应用，Update 不会要求用户重新安装已卸载的应用。系统设备名称、蓝牙设置和蓝牙适配器实际名称必须均为 `JT600_序列号后四位`。`101502000000059C` 的另一种 GSL 触摸实现不在本版本支持范围内。

## 立即停止的情况

- 设备型号或目标版本无法确认；
- AndroidTool 显示的分区、地址、长度与预加载配置不一致；
- 校验失败、进度卡住、工具要求擦除或低级格式化；
- 需要选择 Loader、Resource、校准/NVRAM 或未知分区；
- 设备连续多次无法启动。

停止后保留现场，不要继续尝试其他镜像或恢复操作，交给熟悉 Rockchip 分区和 JT600 的人处理。
