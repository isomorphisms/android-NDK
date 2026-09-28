# Physical outputs

This directory owns copied hardware research for actuators and outward-facing device control, for example:

- speaker/output audio;
- vibrator/haptics;
- flashlight/torch and other lights;
- GPIO pins used as outputs;
- display/backlight control when the subject is the physical output path rather than GPU rendering;
- other actuators.

## Current evidence state

No completed MIRO A1 or TAB_P10 hardware-specific output dossier has yet been promoted here.

Existing work currently establishes only planning boundaries:

- Cheap Phone OS lists lights/flashlight before audio/radio in the hardware bring-up order.
- Audio work is being split into generic Android-native, lower Linux/PCM, and SoC/device-specific layers, but no completed SC9863A/A333 codec or speaker-path hardware receipt has been saved yet.
- Board/pinmux research exists under `../board-and-kernel/`, but no GPIO pin should be labeled as a usable physical output until its board function and privilege/control path are proven.
- Touchscreen GPIOs belong to the input-device dossier, not here.

Add one file per proven output device/path rather than accumulating an undifferentiated hardware dump.
