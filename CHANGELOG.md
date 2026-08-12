# Changelog

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
