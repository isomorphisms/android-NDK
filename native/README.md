# Reusable native Android interfaces

This directory owns reusable Android-native boundaries.  It does not own an
application's mathematics, renderer, domain state, manifest, permission UI, or
device-specific hardware discoveries.

| Area | Current implementation | Boundary |
| --- | --- | --- |
| audio | [`audio/`](audio/) | portable PCM-input contract plus an Android AAudio backend |
| sensors | [`sensors/accelerometer/`](sensors/accelerometer/) | Android NDK accelerometer event adapter |

Each imported implementation is an exact source copy at the recorded revision.
The surrounding README names the source repository and identifies what remains
with its application or hardware project.  See
[`../provenance/migration-inventory.md`](../provenance/migration-inventory.md)
for the complete accounting.

These interfaces sit above Android's framework/system-service and HAL layers.
They do not claim direct access to a particular sensor chip, audio codec,
kernel driver, or bus.
