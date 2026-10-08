<!--
SPDX-FileCopyrightText: 2026 contributors
SPDX-License-Identifier: Apache-2.0
-->

# LS-G scratch: a spec citing a GPL-2.0 OR MIT device-tree pin (do not merge)

Scratch input for driver-lab's license-split acceptance (LS-G, item 2). The device tree and its
facts are synthetic. Expected: passes `hardware-specs-permissive` and `hardware-specs-gpl`,
fails `hardware-specs-docs`.

Source pin: dts@2222222 GPL-2.0 OR MIT

## Facts

- The UART is at 0xfe201000. [src:dts: arch/arm64/boot/dts/widget/widget.dtsi:40]
- The UART's interrupt is SPI 57. [src:dts: arch/arm64/boot/dts/widget/widget.dtsi:44]
