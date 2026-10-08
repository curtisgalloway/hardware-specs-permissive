<!--
SPDX-FileCopyrightText: 2026 contributors
SPDX-License-Identifier: Apache-2.0
-->

# LS-G scratch: a spec citing a GPL-2.0-only pin (do not merge)

Scratch input for driver-lab's license-split acceptance (LS-G, item 2). The device and its
facts are synthetic. Expected: fails `hardware-specs-docs` and `hardware-specs-permissive`,
passes `hardware-specs-gpl`.

Source pin: linux@1111111 GPL-2.0-only

## Facts

- CTRL is at offset 0x10. [src:linux: drivers/net/widget/widget.c:42 (WIDGET_CTRL)]
- Setting CTRL bit 0 resets the block. [src:linux: drivers/net/widget/widget.c:118]
