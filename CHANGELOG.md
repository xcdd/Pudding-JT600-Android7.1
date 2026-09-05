# Changelog

## 1.2 - 2026-09-05

- Finalized the validated JT600 combination `K71M147/B71M29/S71M57/R71M0` and retained the K124 dual-display selection and accepted display wake/brightness behavior.
- Fixed the AP6212 SDIO DAT0 pinmux loss after long suspend/resume in Kernel K71M147; the five-day operator WiFi observation passed.
- Added the A2DP Sink short-audio fix in System S71M57: streams without AVRCP Play are accepted and decoding starts on the first AVDTP packet, so system notifications and meeting audio do not depend on background music.
- Updated Factory and custom-system Update workflows for Kernel build `#161`; Update writes only Kernel and System and does not require previously uninstalled preload apps to reappear.
- Improved `Run-JT600Flash-Update.cmd`: it detects an Android ADB device and asks whether to enter BL automatically before launching AndroidTool.
- Update confirms a single Rockusb Loader before opening AndroidTool; Factory-only device backups are never requested by Update mode.
- Kept each device's original Resource; the `101502000000059C` GSL touch implementation is explicitly outside this release's support scope.
- Replaced whole-image SHA-256 preflight reads with fast release-manifest, file-name and exact-size checks; post-write runtime verification remains required.

## 1.1 - 2026-08-12

- Fixed Factory verification so an unmounted `/data` is initialized immediately from the task's Factory mode; it no longer depends on an optional command-line switch or waits for an impossible boot completion.
- Replaced the regressed S71M52 System with S71M53, based on the accepted S71M51 release content plus the per-device name fix; post-write verification now requires all five uninstallable preload apps, the S71M53 release marker and `JT600_<serial suffix>` names.
- Fixed Factory runs getting stranded at the Android boot animation when AndroidTool completed a manual write without recording `RunProc ret=1`; the workflow now verifies the flashed System, Kernel and userdata size on-device before automatically initializing `/data`.
- Updated Factory and custom-system update workflows for the JT600 V1.1 combination `K71M122/B71M29/S71M53/R71M0`; update mode now writes the required Kernel and System pair.
- Added post-write comparison of `ro.build.display.id` and the Kernel build number with the release manifest so an incomplete or mismatched V1.1 combination cannot be reported as accepted.
- Replaced generated Factory IMAGE configurations with an explicit human-readable AndroidTool write table. The script validates inputs and opens the all-unselected tool only.
- Replaced AndroidTool's obsolete ADB 1.0.31 with the tested platform-tools ADB 1.0.41 so Windows 11 can enumerate the JT600 USB ADB interface.

## 1.0 - 2026-08-11

- Published JT600 Android 7.1 flashing instructions for factory devices and devices already running the custom system.
- Added USB driver installation, original-device backup, AndroidTool v2.38 configuration generation, flashing orchestration and post-write verification scripts.
- Replaced the vendor AndroidTool startup table with a zero-selected safe default; task scripts generate and verify the selected rows before launch.
- Added SensorTest 1.1 source, reproducible Gradle project, platform-signed prebuilt APK and signing workflow.
- Added CC BY-NC-SA 4.0 licensing and third-party notices.

## Maintenance rules

- Keep the public version in `README.md`, `docs/sensortest.md`, the APK manifest and `artifacts/README.md` identical.
- For every prebuilt APK, update `artifacts/SHA256SUMS.txt`, signer fingerprint and the corresponding release entry here.
- Keep firmware and local signing material under `firmware-package\`; never publish them in the source repository.
- When a partition address, required file name or AndroidTool version changes, update the generator, the flashing guide and the firmware package README together.
