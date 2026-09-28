# MIRO A1 accelerometer and sensor-layer research

Copied from `Ashtray-Archer/utilities-android-phone-user`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/4  
Original cross-index: https://github.com/Ashtray-Archer/utilities-android-phone-user/issues/77

## Proven native Android boundary

Merged accelerometer work uses the stable NDK/libandroid sensor path:

```text
ASensorManager
ASensor
ASensorEventQueue
ALooper
```

The physical ARMv7 receipt proves that this path reads the actual phone accelerometer.

## Exact physical receipt

```text
workflow run       34669980204
source head        617f56565d53127a63e2d9a905d2b779485fa5c5
ABI                armeabi-v7a
binary             hardware-android-native-armv7
binary sha256      72b4a43d20cca8f897a0df424d2588cd8b948ec77e83ecf63157072066085d43
Android            14 / API 34
kernel             5.15.149-android13-8-g8407b75767d0-dirty
process UID        10276
SELinux context    u:r:untrusted_app:s0:c20,c257,c512,c768
```

Selected sensor:

```text
name               acc_sc7a20
vendor             Silan
type               1 (accelerometer)
units              m/s^2
resolution         0.00960000046
minimum delay      5000 us
```

One physical one-shot sample was:

```text
-8.9508009 -1.89360011 -3.33120012
```

Five bounded event samples also completed successfully.

## Lower-layer reconnaissance

From the same untrusted-app context:

Visible:

```text
/dev/binder
/dev/hwbinder
android.frameworks.sensorservice.ISensorManager/default
android.hardware.sensors.ISensors/default
sensorservice (android.gui.SensorServer)
```

Not proven as working direct-read boundaries:

- direct Binder sensor transaction;
- direct sensors HAL read.

Explicitly denied/unavailable in this context:

```text
dumpsys sensorservice        denied for uid 10276
/dev/input                   absent
/sys/class/input             exists, not readable by shell test
/sys/bus/iio/devices         exists, not readable by shell test
/dev/i2c-0                   absent
/dev/spidev0.0               absent
/dev/mem                     absent
```

Therefore the lowest **proven working sensor-read boundary** remains the public native `libandroid` sensor API.

## Second MIRO A1 sensor inventory

A later physical `adb shell dumpsys sensorservice` receipt on the second MIRO A1 reported the Silan `acc_sc7a20` as four Android sensor entries:

- calibrated accelerometer;
- uncalibrated accelerometer;
- wake-up calibrated accelerometer;
- wake-up uncalibrated accelerometer.

A targeted dump/grep produced no gyroscope or magnetic-field entries.

Interpret this narrowly: Android did not advertise those gyro/magnetometer sensors in that receipt. It does not prove that no electrically present but unexposed device exists.

Sensor discovery should therefore be capability-driven rather than assuming every phone has accelerometer + gyro + magnetometer.

## API layering kept for comparison

The research preserves distinct possible layers:

```text
android-native
direct Binder
direct sensors HAL
kernel /dev, /sys, IIO/input/vendor nodes
sensor hub / I2C / SPI / MMIO
```

A permission/SELinux denial is evidence about reachability, not a successful lower-layer implementation.

## Canonical sources

- https://github.com/Ashtray-Archer/utilities-android-phone-user/issues/43
- merged implementation PR #44 in that repository
- physical receipts in issue #43 comments
- `accelerometer/README.md`
