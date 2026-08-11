# Changelog

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
