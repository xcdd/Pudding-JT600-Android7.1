# JT600 刷机说明（新手版）

## 这件事是什么

“刷机”是把设备中的 Android 系统文件替换成另一套系统文件。过程中设备可能暂时黑屏，也可能清除数据；文件或步骤不匹配时，设备可能无法正常启动。

刷机文件放在仓库根目录的 `firmware-package\` 目录中。没有明确写着与你的 JT600 型号和目标版本匹配的文件时，不要猜测、拼接或借用其他设备的文件。

## 先判断设备状态

- **保留原厂布丁豆豆系统的设备**：走“原厂首次刷写”流程，一次性写入完整系统和扩容配置，使 userdata 达到 5 GiB；不要只写 System。
- **已经刷入我们定制系统的设备**：只更新 System。设备可以在刷写后用 USB ADB 自动验收。

## 固件包和工具目录

把完整的对外版本发布包放入 `firmware-package\`，以发布包自己的 `README.md`、`RELEASE-MANIFEST.txt` 和 `SHA256SUMS.txt` 为准，不要改文件名或自行替换文件。脚本会读取发布清单并验证其中记录的大小和 SHA-256。

工具目录只需要准备两个文件夹：`AndroidTool-v2.38` 和 `DriverAssistant-v5.14`。脚本会自动使用这两个文件夹，不要求用户逐个寻找工具文件。

打包目录中的 AndroidTool 默认配置是无操作配置：直接打开时所有写入项均未选中。实际刷写配置只由对应脚本临时生成。

## 原厂设备首次刷写

1. 只准备一台 JT600，接通稳定电源，拔掉其他同类设备。
2. 双击 `tools\flash\00-install-drivers.cmd`，完成 Rockchip USB 驱动安装。必须先安装驱动，再启动 AndroidTool。
3. 双击 `tools\flash\00-export-original-jt600.cmd`。脚本先启动本地 AndroidTool。
4. AndroidTool 窗口打开后，设备关机，插入 USB，用卡针或回形针按住 microUSB 口旁的小孔。听到电脑的 USB 连接声、并在 AndroidTool 中看到 Loader 后松开。
5. 脚本会依次提示导出本机的 `metadata.img`、`kpanic.img` 和 `parameter-original.bin`。每次按当前提示填写起始扇区和扇区数，点击“导出镜像”；脚本会自动检查大小、计算 SHA-256、保存文件并提示下一项。三个文件全部完成前不要关闭 AndroidTool。
6. 双击 `tools\flash\Run-JT600Flash-Factory.cmd`。脚本自动使用 `firmware-package\` 中的固件、AndroidTool 和刚才的备份。
7. 脚本验证发布清单中的所有输入并打开已预加载的 AndroidTool。确认只有发布说明要求写入的项目被勾选，Loader 没有勾选，然后由人类点击“执行”。
8. 等待下载和校验都显示 100%，设备自动重启。脚本随后等待 USB ADB；这是刷写后的验收阶段，不是刷写前提。
9. 原厂首次刷写后 `/data` 一定尚未初始化；不完成这一步设备无法正常启动。脚本确认 userdata 恰为 5 GiB 后会自动初始化 `/data`、重启并继续验收。

## 已刷入定制系统的设备

1. 双击 `tools\flash\00-install-drivers.cmd`，完成驱动安装。
2. 双击 `tools\flash\Run-JT600Flash-Update.cmd`，脚本先启动已准备好的 AndroidTool。
3. AndroidTool 窗口打开后，设备关机并按上面的方式插入 USB、进入 Loader；如果当前系统有 USB ADB，也可以先重启到 Loader。
4. AndroidTool 会预加载只勾选 System 的配置。确认 Loader、Kernel、Boot、Parameter 和其他行均未勾选，再由人类点击“执行”。
5. 等待 100% 下载和校验，脚本自动通过 AndroidTool 自带的 USB ADB 做写后检查。

## 验收

脚本会显示设备序列号、系统显示版本、启动完成状态和 SELinux。ADB 的连接方式由设备使用者自行决定，脚本不改变 ADB 传输设置。

## 立即停止的情况

- 设备型号或目标版本无法确认；
- AndroidTool 显示的分区、地址、长度与预加载配置不一致；
- 校验失败、进度卡住、工具要求擦除或低级格式化；
- 需要选择 Loader、Resource、校准/NVRAM 或未知分区；
- 设备连续多次无法启动。

停止后保留现场，不要继续尝试其他镜像或恢复操作，交给熟悉 Rockchip 分区和 JT600 的人处理。
