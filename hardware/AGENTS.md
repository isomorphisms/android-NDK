# Hardware research filing rules

Keep this tree useful as a shared Android-native hardware reference rather than a second miscellaneous notebook.

## File by hardware function

- `board-and-kernel/`: SoC/board identity, DT/DTBO, buses, clocks, pinmux, regulators, boot/kernel and generic GPIO infrastructure.
- `cpu/`: instruction set, microarchitecture, CPU ABI and CPU-specific execution facts.
- `gpu/`: GPU/driver identity, GLES/Vulkan capabilities, precision behavior and GPU execution evidence.
- `memory-and-storage/`: RAM, zram, flash/storage transport and memory hierarchy.
- `sensors-and-inputs/`: accelerometers, gyro/magnetometer if present, touchscreens, microphones when treated as input hardware, buttons and input-specific pins.
- `physical-outputs/`: speakers, vibration/haptics, flashlight/lights, GPIO output pins, actuator control and physical display/backlight paths.
- `runtime-abi/`: Bionic, ART/JNI, page size and physical Android ABI receipts that constrain NDK code but are not hardware-block dossiers themselves.

If one fact crosses folders, keep the canonical copied explanation in the narrowest hardware folder and cross-link rather than duplicating the full note.

## Provenance

Every copied dossier must name:

1. the original repository;
2. the original issue/PR/file when known;
3. the Android-NDK cross-index issue when one exists.

The original repository remains canonical unless the project explicitly changes ownership later.

## Evidence levels

Label claims mentally and in prose as:

- **physical** — observed on the actual device;
- **model** — documentation for that product/model;
- **platform/reference** — SoC/BSP/reference-board documentation;
- **unknown** — not established.

Never turn a reference board value into a physical-board fact.

A denied syscall, Binder transaction, sysfs read or SELinux operation is useful reachability evidence, but it is not a successful hardware operation.

An emulator, Mesa/llvmpipe or host build is not physical-device evidence.

## Keep unknowns

Write `unresolved` or `UNKNOWN` instead of filling gaps from a nearby device. This especially applies to:

- board pin assignments;
- regulators/power rails;
- codecs and amplifier paths;
- vibrator/haptic drivers;
- camera modules;
- Wi-Fi/Bluetooth parts;
- charger/battery ICs;
- storage package/vendor/geometry.

## Privacy

Do not copy IMEIs, Android IDs, unique storage CIDs/serials or other unnecessary unique device identifiers into the public research tree.

## Index maintenance

When a new hardware dossier is added:

1. place it in the correct folder;
2. add it to `hardware/README.md`;
3. cross-link its original location and Android-NDK issue;
4. keep implementation code elsewhere unless it genuinely belongs to the Android NDK interface itself.
