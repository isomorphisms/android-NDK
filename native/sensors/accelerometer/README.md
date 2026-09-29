# Android NDK accelerometer adapter

Status: canonical reusable Android sensor-stack adapter, copied without source
edits from
[`Ashtray-Archer/utilities-android-phone-user` at `a8722e10318c63ea656729ee2c2cce526a423754`](https://github.com/Ashtray-Archer/utilities-android-phone-user/tree/a8722e10318c63ea656729ee2c2cce526a423754/accelerometer/android).

`android_accelerometer.[ch]` exposes an ordinary NDK/`ASensorManager` event
queue: open, enable, drain events, disable, and close.  Its public value is an
**Android accelerometer reading**: the Android sensor-event timestamp plus
three binary32 acceleration components in m/s².  It is not a chip register,
ADC count, raw bus transaction, or direct HAL call.

The source project still owns the compact geometric state, inspection model,
CLI, NativeActivity screen, package shapes, and its detailed hardware work.
Its hardware provenance remains at
[`hardware/README.md`](https://github.com/Ashtray-Archer/utilities-android-phone-user/blob/a8722e10318c63ea656729ee2c2cce526a423754/hardware/README.md).
The target-specific MIRO A1 dossier is retained here as a reference at
[`../../../hardware/sensors-and-inputs/miro-a1-accelerometer.md`](../../../hardware/sensors-and-inputs/miro-a1-accelerometer.md),
with the original source still canonical for device facts.

Android's public sensor API, Binder/sensorservice, HAL, kernel interfaces, and
chip/bus access are different layers.  A successful adapter read establishes
only the public Android sensor-stack boundary.
