# MIRO A1 / SC9863A board and kernel research

Copied from the hardware work in `fuego-ironworks/cheap-phone-os`.

Cross-index: https://github.com/isomorphisms/android-NDK/issues/1  
Original cross-index: https://github.com/fuego-ironworks/cheap-phone-os/issues/63

## Physical platform receipt

Observed on the physical MIRO A1:

```text
ro.board.platform = sp9863a
ro.hardware = s9863a1h10_go_32b
ro.boot.hardware = s9863a1h10_go_32b
kernel = 5.15.149-android13-8-g8407b75767d0-dirty
```

This identifies the Spreadtrum/UNISOC SC9863A / SharkL3 / 1H10 platform family. It does **not** prove electrical identity with another SP9863A-1H10 board.

## Boot/storage structure

Physical `/dev/block/by-name` evidence includes A/B copies of:

```text
spl_a spl_b
trustos_a trustos_b
sml_a sml_b
uboot_a uboot_b
pm_sys_a pm_sys_b
teecfg_a teecfg_b
boot_a boot_b
vendor_boot_a vendor_boot_b
init_boot_a init_boot_b
dtb_a dtb_b
dtbo_a dtbo_b
vbmeta_a vbmeta_b
```

The modem/DSP firmware is separately partitioned, including `l_modem_*`, `l_gdsp_*`, `l_ldsp_*`, NV partitions and runtime-NV partitions. Early bring-up work should leave those firmware partitions alone.

## Kernel bring-up boundary

The first replacement boundary was deliberately:

```text
stock Boot ROM / SPL / secure firmware / U-Boot
    -> replacement Linux kernel
    -> MIRO device tree
    -> tiny initramfs
    -> console
```

The first device-support tranche covers:

- UART;
- I2C;
- SPI;
- GPIO/EIC;
- DMA;
- SC9863A clocks;
- regulator/reset/pinctrl infrastructure;
- eMMC/SD/SDIO;
- USB plumbing.

Display, touch, battery/charging, sensors, audio, radio, Wi-Fi/Bluetooth and cameras require board-specific evidence and must not be inferred from generic SoC support.

## Public exact-target material

The exact target string `s9863a1h10_go_32b` appears in public UNISOC-derived source trees.

Useful source families recovered in the original research include:

- `jingpad-bsp/device_sprd_sharkl3`, directory `s9863a1h10_go_32b/`;
- `deadman96385/jingpad_android_bsp`, directory `device/sharkl3/androidq/s9863a1h10_go_32b/`;
- `strongtz/linux-sprd`;
- `MotorolaMobilityLLC/kernel-sprd`;
- `turtleletortue/android_kernel_retroid_pocket2plus`;
- `coldraintea/SPRD-stuff`, directory `sharkl3/s9863a1h10_go_32b/`.

Recovered target configuration includes:

```text
TARGET_BOARD_PLATFORM := sp9863a
TARGET_BOARD := s9863a1h10_go_32b
PRODUCT_GO_DEVICE := true
BSP_BOARD_NAME="s9863a1h10_go_32b"
BSP_BOARD_ARCH="arm"
BSP_KERNEL_DEFCONFIG="sprd_sharkl3_defconfig"
```

Useful vendor-derived paths include:

```text
arch/arm/configs/sprd_sharkl3_defconfig
sprd-board-config/sharkl3/sp9863a_1h10/
arch/arm/boot/dts/sp9863a-1h10_go_32b-overlay.dts
u-boot15/board/spreadtrum/sp9863a_1h10/pinmap-sp9863a.c
```

## Pinmux research

SC9863A customer material describes pin configuration in terms of:

- alternate-function selection;
- drive strength;
- pull-up/pull-down;
- strong pull-up;
- sleep-state ownership;
- sleep pull state;
- sleep input/output/high-impedance state;
- UART/SPI/I2C/SIM matrix routing.

Named matrix registers include:

```text
REG_PIN_UART_MATRIX_MTX_CFG
REG_PIN_UART_MATRIX_MTX_CFG1
REG_PIN_IIS_MATRIX_MTX_CFG
REG_PIN_SIM_MATRIX_MTX_CFG
REG_PIN_SPI_MATRIX_MTX_CFG
REG_PIN_IIC_MATRIX_MTX_CFG
```

Do not substitute a nearby SC9860 pin table blindly. The exact SC9863A table and the MIRO board assignments need their own evidence.

## Mainline Linux reference

Linux 5.15 contains useful Spreadtrum/UNISOC support, including:

```text
arch/arm64/boot/dts/sprd/sc9863a.dtsi
arch/arm64/boot/dts/sprd/sharkl3.dtsi
arch/arm64/boot/dts/sprd/sp9863a-1h10.dts
drivers/clk/sprd/sc9863a-clk.c
drivers/tty/serial/sprd_serial.c
drivers/i2c/busses/i2c-sprd.c
drivers/spi/spi-sprd.c
drivers/dma/sprd-dma.c
drivers/gpio/gpio-sprd.c
drivers/gpio/gpio-eic-sprd.c
drivers/mmc/host/sdhci-sprd.c
```

The upstream SP9863A-1H10 DTS is a reference board, not proof of MIRO wiring.

## Stage-0 bundle work

Cheap Phone OS PR #59 added the first non-flashable MIRO stage-0 kernel bundle using a pinned public ARM32 SharkL3 donor. The bundle contains:

- `zImage`;
- `sp9863a.dtb`;
- an exact-family DTBO;
- tiny static initramfs;
- kernel configuration;
- SHA-256 receipts.

It intentionally creates no `boot.img` and performs no flashing.

## Highest-value next board evidence

Recover and hash the physical:

```text
dtb_a
dtbo_a
```

Then compare:

```text
MIRO DTB/DTBO
    vs exact s9863a1h10_go_32b vendor-derived overlays
    vs UNISOC 1H10 BSP
    vs mainline sp9863a-1h10.dts
```

That comparison should resolve more of the display, touch, sensor, GPIO, regulator, USB and other board-specific map.

## Canonical sources

- https://github.com/fuego-ironworks/cheap-phone-os/pull/50
- https://github.com/fuego-ironworks/cheap-phone-os/pull/59
- `fuego-ironworks/cheap-phone-os/hardware/miro-a1/README.md`
- `fuego-ironworks/cheap-phone-os/hardware/sc9863a/README.md`
