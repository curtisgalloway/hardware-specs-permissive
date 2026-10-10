<!--
SPDX-FileCopyrightText: 2026 contributors
SPDX-License-Identifier: Apache-2.0
-->

# hardware-specs-permissive

Instructions for coding agents working in this repository. The user guide is the
[README](README.md).

- **What this is:** published hardware specs in spec format 2, licensed Apache-2.0. The method lives
  in [driver-lab](https://github.com/curtisgalloway/driver-lab): the contract for specs, the
  root marker and verification records is its `skills/spec-format/SKILL.md` (with the JSON
  Schemas it names, which define every record's fields), `spec.py` is the tool, and
  `spec-verifier` writes the verification records. Read the contract before writing or changing
  a spec; do not restate it here.
- **Placement first:** apply the README's placement rule before adding a spec. A spec citing a
  source this repository's `accepts:` does not list belongs in another spec repository, or in
  none.
- **What a spec here may cite:** `src` and `DT` support anchored to `resources.repos` entries
  whose `license` is BSD, ISC, 0BSD, MIT or Apache (and `GPL-2.0 OR MIT` files, through an entry
  whose license says so), each at a full commit with a `files` list, plus documents under
  `resources.documents`. A spec that reproduces material from a BSD-, ISC- or MIT-licensed
  source keeps that source's copyright notice and license in its `notices` field and gets a
  line in `NOTICE`.
- **Overlays on docs specs:** an overlay here may target a spec in `hardware-specs-docs`
  (`kind: overlay`, `overlays: <spec id>`). A reference to one of its facts is root-qualified,
  `"<spec id>@hardware-specs-docs#<fact id>"`. CI checks out that repository's `main` as a
  context root; `scripts/checks.sh all <driver-lab> <hardware-specs-docs checkout>/specs` does
  the same locally.
- **Names:** every spec is `specs/<name>.spec.yaml` (`kind` says what it is; an overlay uses a
  filename distinct from its target's id when the target is in this root), and its verification
  record is `specs/resources/<name>.verify.yaml`. A fact's `id` is stable: never reuse or rename
  one, since verdicts and other repositories' references name it. After editing a spec, re-run
  `spec-verifier` on the changed facts (`spec.py status --stale` lists them).
- **Generated views:** the Markdown view and the viewer are built by CI (`publish.yml`) and
  published to the repository's GitHub Pages site; never commit or hand-edit a view.
- **Checks:** `CHECKS_PYTHON=<venv>/bin/python RESOLVE_SRC=1 scripts/checks.sh all <driver-lab
  checkout> <hardware-specs-docs checkout>/specs` runs what CI runs (it exits 2 without the further root); the venv holds driver-lab's
  `skills/spec-format/requirements.txt`, installed with `pip install --require-hashes`. The
  default `--mode pr` is the pull-request policy; CI runs `--mode main` on `main`. CI pins
  driver-lab to the commit in `.github/workflows/checks.yml`, and `publish.yml`'s `TOOL_COMMIT`
  names the same commit: bump both together, and check against that commit.
- **Do not** widen `accepts:` in `specs/board-specs.yaml` to make a spec pass: that changes the
  repository's license policy, which is the user's decision. Do not add the self-test's fixture
  specs to `specs/`.
- **License headers:** every file except the license texts carries
  `SPDX-FileCopyrightText: 2026 contributors` and its `SPDX-License-Identifier`. In a spec, a
  verification record or the root marker they are YAML comment lines (`# SPDX-...`) at the top
  of the file; in Markdown, an HTML comment.
- **Privacy:** this repository is public. No host names, addresses, user names or home paths in
  any file or commit message.
- **Git:** a topic branch and a pull request per change; push or open a pull request only on the
  user's explicit "push".
