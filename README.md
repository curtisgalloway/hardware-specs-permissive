<!--
SPDX-FileCopyrightText: 2026 contributors
SPDX-License-Identifier: Apache-2.0
-->

# hardware-specs-permissive

Hardware specs that cite source trees under BSD, MIT or Apache licenses (and files
dual-licensed `GPL-2.0 OR MIT`, used under their permissive option), plus public documents,
licensed Apache-2.0 with a [NOTICE](NOTICE) file for the BSD and MIT sources. Typical sources:
Trusted Firmware-A (TF-A), the Raspberry Pi tools, Zephyr, FreeBSD and dual-licensed device
trees. A spec here may be an *overlay* that adds facts to a spec in
[hardware-specs-docs](https://github.com/curtisgalloway/hardware-specs-docs); CI checks the two
repositories together so such an overlay always finds its target.

**Every claim is anchored, and the checker runs in CI.** Each fact in a peripheral spec here names the line of a pinned source tree or the page of a listed document it rests on; each fact in a board spec carries a tag for its kind of source and, for documents and device trees, names the source. Every push and pull
request runs driver-lab's checkers over the whole repository: a malformed anchor or tag, or a
source whose license this repository does not accept, fails the build. There are no specs here
yet; they are being regenerated with the current tools.

**Terms.** A *spec* is a hardware description that driver authors, people or AI agents, read
instead of the original sources; a *peripheral spec* covers one device, a *board spec* a board or
chip. An *anchor* is a citation inside a spec: `[src:<pin>: path:L]` points at a line of a source
tree, `[doc:<name> p.N]` at a page of a document. A *pin* (`Source pin: linux@<commit>
GPL-2.0-only`) names that tree, its commit and the license of the cited files, written in SPDX,
the standard license-identifier language. `specs/board-specs.yaml` is this repository's *root
marker*: it states the repository's license and its *accepts list*, the licenses a cited source
may carry. The *license gate* is the check that fails a spec citing a source outside that list.
Full definitions: driver-lab's [glossary](https://github.com/curtisgalloway/driver-lab/blob/main/GLOSSARY.md).

## Which repo does my spec go in?

**Placement rule:** a spec lives in the most restrictive repository among the sources it anchors
to. A spec may reference repositories with less restrictive licenses, never ones with more
restrictive licenses.

| Repo | License | Anchors allowed | Holds |
|---|---|---|---|
| `hardware-specs-gpl` | GPL-2.0-only | `[src:]` into any GPL-2.0-only or GPL-2.0-or-later tree, plus `[doc:]`, plus anything the permissive repo accepts | Linux-derived specs: references for Linux work, or for anyone who doesn't care about license. Easiest to verify. |
| `hardware-specs-docs` | CC-BY-4.0 (specs); per-file Apache-2.0 SPDX headers on CI files | `[doc:]` only | Specs built only from public datasheets, TRMs and standards |
| `hardware-specs-permissive` | Apache-2.0, plus a NOTICE file for the BSD/MIT sources | `[src:]` into BSD, MIT or Apache trees (and `GPL-2.0 OR MIT` files), plus `[doc:]` | TF-A, rpi-tools, Zephyr, FreeBSD, dual-licensed device trees. First material: the bcm2711 overlay (facts 2, 3, 6 below) |

The table is the license-split design's ([LICENSE-SPLIT.md](https://github.com/curtisgalloway/driver-lab/blob/main/docs/LICENSE-SPLIT.md#the-repos)),
verbatim; its "facts 2, 3, 6 below" are three boot-stub facts from BSD-licensed Raspberry Pi
tools, listed in that design's audit of the deleted specs.

This repository accepts sources licensed `Apache-2.0`, `MIT`, `BSD-2-Clause`, `BSD-3-Clause` (`accepts:` in [specs/board-specs.yaml](specs/board-specs.yaml)).

## What is here

- `specs/`: the specs and the root marker. Peripheral specs are named `<device>-spec.md`, board
  specs `<id>.spec.md`.
- `LICENSE`: the license.
- `NOTICE`: attribution for BSD- and MIT-licensed sources.
- `.github/workflows/checks.yml` and `scripts/checks.sh`: the checks below.

## How a spec is written and checked

The method lives in [driver-lab](https://github.com/curtisgalloway/driver-lab): the
[`anchored-peripheral-spec`](https://github.com/curtisgalloway/driver-lab/tree/main/skills/anchored-peripheral-spec) skill writes and
verifies peripheral specs and defines the anchor grammar;
[`SPEC-FORMAT.md`](https://github.com/curtisgalloway/driver-lab/blob/main/skills/board-expert/SPEC-FORMAT.md) defines board specs and
the root marker. CI checks out driver-lab at one pinned commit and runs, through
`scripts/checks.sh`:

1. `spec_check.py specs .hardware-specs-docs/specs --require-license`: the root marker's license fields and every
   board spec, including the board-spec license gate on `resources.repos` licenses.
2. `anchor_check.py <spec> --root specs --require-license` on every peripheral spec: anchors,
   pins and the license gate. CI has no checkout of the cited source trees, so it checks the
   anchors' form and licenses; resolving each `[src:]` line against its tree is part of
   verification (the skill's verify step).
3. A self-test that proves the gate works with this repository's own root marker: driver-lab's
   fixture specs that fit and do not fit this repository are copied into a temporary root, and
   the run fails unless the misfits fail with the gate's message and the fits pass. The fixtures
   are never published here as specs.

To run the same checks locally:

```bash
git clone https://github.com/curtisgalloway/driver-lab ../driver-lab
git clone https://github.com/curtisgalloway/hardware-specs-docs ../hardware-specs-docs
scripts/checks.sh all ../driver-lab ../hardware-specs-docs/specs
```

The script needs bash and python3 (standard library only).

Check out the driver-lab commit that `.github/workflows/checks.yml` pins for an identical run.

## License

Everything here is licensed Apache-2.0 ([LICENSE](LICENSE)); each file states it in an
`SPDX-License-Identifier` line. [NOTICE](NOTICE) explains how facts drawn from BSD- and
MIT-licensed sources carry their source's attribution.
