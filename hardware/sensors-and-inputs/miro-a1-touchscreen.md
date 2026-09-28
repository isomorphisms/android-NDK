# MIRO A1 touchscreen hardware research

Copied from `fuego-ironworks/cheap-phone-os`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/2  
Original cross-index: https://github.com/fuego-ironworks/cheap-phone-os/issues/64

## Exact-target public reference

A vendor-derived `sp9863a-1h10_go_32b-overlay.dts` for the same UNISOC board target contains:

```dts
&i2c3 {
    status = "okay";

    touchscreen@38 {
        compatible = "adaptive-touchscreen";
        reg = <0x38>;
        gpios = <&ap_gpio 145 GPIO_ACTIVE_HIGH
                 &ap_gpio 144 GPIO_ACTIVE_HIGH>;
        controller = "focaltech,FT5436";
    };
};
```

The binding orders those GPIOs as reset then interrupt.

Reference-target interpretation:

```text
bus           i2c3
controller    FocalTech FT5436
address       0x38
reset         AP GPIO 145
interrupt     AP GPIO 144
```

Reference SharkL3 pad mapping:

```text
SHARKL3_EXTINT0 -> GPIO 144
SHARKL3_EXTINT1 -> GPIO 145
SHARKL3_SCL3    -> GPIO 146
SHARKL3_SDA3    -> GPIO 147
```

Reference I2C3 controller data:

```text
MMIO address    0x70800000
IRQ             GIC SPI 14
bus frequency   400000 Hz
enable clock    CLK_I2C3_EB
I2C clock       CLK_AP_I2C3
source clock    ext_26m
reset           MASK_AP_APB_I2C3_SOFT_RST
```

These were reference values until compared with the physical phone.

## Physical Termux visibility receipt

A stock MIRO A1 Termux probe could read:

```text
/vendor_dlkm/lib/modules/focaltech_ats.ko
/vendor_dlkm/lib/modules/il79451a_touch_spi.ko
/vendor/etc/sinput/adaptive_ts.conf
```

The same app UID could not directly inspect the live touchscreen DT/I2C/input inventory and was denied access to several proc/dumpsys paths.

Important consequence: module presence alone could not select the installed controller, because the vendor image carried both a FocalTech path and an Ilitek SPI option.

## Physical stock adaptive-touch configuration

Readable `/vendor/etc/sinput/adaptive_ts.conf` on the physical MIRO contains:

```text
int_pin_offset    0x58
rst_pin_offset    0x5c
int_gpio_num      14
rst_gpio_num      15
pin_fun_mask      0x30
int_fun_ns        3
int_fun_se        2
rst_fun_ns        3
rst_fun_se        2
spi_max_speed_hz  0
width             720
height            1280
i2c_intf          3
i2c_bus           3
i2c_addr          0x38
spi_intf          0
spi_bus           0
spi_chip_select   0
spi_mode          0
spi_bits_per_word 0
vendor            focaltech
product           FT5x46
```

This physically confirms the stock MIRO build is configured for a **FocalTech FT5x46-family touchscreen over I2C bus 3 at address 0x38**, not the alternate Ilitek SPI path.

## GPIO numbering boundary

Secure-input configuration names:

```text
interrupt GPIO 14
reset GPIO     15
```

The older Linux board overlay names:

```text
interrupt AP GPIO 144
reset AP GPIO     145
```

The roles agree. The numbering differs by 130 in this case.

Do **not** generalize `14 -> 144` and `15 -> 145` into a universal GPIO-number translation rule until the secure-input GPIO mapping or merged MIRO device tree is recovered.

## Current map

```text
controller family   FocalTech FT5x46     physical stock config
transport           I2C                  physical stock config
I2C interface       3                    physical stock config
I2C bus             3                    physical stock config
I2C address         0x38                 physical stock config
surface config      720 x 1280           physical stock config

Linux reference:
I2C3 MMIO           0x70800000
bus frequency       400 kHz
clock               CLK_AP_I2C3 / ext_26m
SCL/SDA             SCL3 / SDA3
interrupt           AP GPIO 144
reset               AP GPIO 145

secure-touch config:
interrupt number    14
reset number        15
interrupt pin off   0x58
reset pin off       0x5c

power rail          unresolved
```

The exact physical regulator remains unknown. The old binding supports `avdd-supply`, but the public reference node omits it. Do not invent the rail.

## Canonical sources

- https://github.com/fuego-ironworks/cheap-phone-os/pull/57
- `fuego-ironworks/cheap-phone-os/hardware/miro-a1/touchscreen.md`
