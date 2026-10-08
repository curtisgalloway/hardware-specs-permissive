#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 contributors
# SPDX-License-Identifier: Apache-2.0
#
# The checks CI runs (.github/workflows/checks.yml), runnable locally from the top of
# the repository:
#
#   scripts/checks.sh <step> <driver-lab checkout> [<further root>...]
#
# Steps:
#   specs      spec_check.py on specs/ (and any further roots) with --require-license
#   anchors    anchor_check.py --root specs --require-license on every specs/**/*-spec.md
#              and on every board spec (specs/**/*.spec.md) carrying a [src:] anchor, and a
#              failure for any other Markdown file under specs/ that no check reads
#   self-test  prove the license gate with this repository's root marker (below)
#   all        the three in order
#
# A further root is another spec root read beside specs/ so that overlays resolve. It is context
# only: spec_check.py reads it with --context-root, so its own findings are warnings here and
# fail only in its own repository's checks.
#
# RESOLVE_SRC=1 (CI sets it) makes the anchors step fetch each pinned repository a board spec's
# [src:] anchors cite, as a shallow, blob-less clone of the one commit, and resolve the anchors
# against it; an entry whose initial fetch exceeds SRC_FETCH_LIMIT_MB (default 50) or fails is
# checked for form and license only. Unset, nothing is fetched.
# hardware-specs-docs passes none; hardware-specs-permissive requires one, hardware-specs-docs'
# specs/; hardware-specs-gpl requires two, hardware-specs-docs' specs/ then
# hardware-specs-permissive's specs/ (a GPL overlay may add to a docs spec that a permissive
# overlay also adds to).
#
# Needs bash 3.2 or later and python3.
#
# Exit codes: 0 passed, 1 a check failed, 2 usage error, 3 missing precondition.
set -euo pipefail

# This repository's self-test fixtures, from driver-lab's
# skills/peripheral-spec/tests/fixtures/license-gate/ (its README lists each
# repository's pairs). Peripheral specs for the anchor gate:
FIT=bsd-spec.md
MISFIT=gpl-only-spec.md
# Board-spec overlays for spec_check.py's gate, each placed beside board/widgetchip.spec.md
# (an empty BOARD_FIT checks widgetchip.spec.md alone):
BOARD_FIT=widgetchip-bsd-overlay.spec.md
BOARD_MISFIT=widgetchip-gpl3-overlay.spec.md
# How many further roots every step needs (the first is always the docs repository's specs/),
# so the cross-repository overlay check never silently skips.
REQUIRE_FURTHER=1
# Board-spec [src] fixture (widgetchip-src-overlay.spec.md beside widgetchip.spec.md):
# 1 when this repository's marker accepts its BSD-3-Clause source, 0 when it must fail the gate.
SRC_FIT=1

usage() {
  echo "usage: scripts/checks.sh specs|anchors|self-test|all <driver-lab checkout> [<further root>...]" >&2
  exit 2
}

[ "$#" -ge 2 ] || usage
step=$1
dl=$2
shift 2
further=("$@")
if [ "${#further[@]}" -lt "$REQUIRE_FURTHER" ]; then
  echo "usage: hardware-specs-permissive needs $REQUIRE_FURTHER further root(s): scripts/checks.sh $step $dl <hardware-specs-docs checkout>/specs" >&2
  exit 2
fi

SPEC_CHECK=$dl/skills/board-expert/scripts/spec_check.py
ANCHOR_CHECK=$dl/skills/peripheral-spec/scripts/anchor_check.py
FETCH_PINS=$dl/skills/board-expert/scripts/fetch_src_pins.py
FIXTURES=$dl/skills/peripheral-spec/tests/fixtures/license-gate

needed=("$SPEC_CHECK" "$ANCHOR_CHECK" "$FETCH_PINS" "$FIXTURES/specs/$FIT" "$FIXTURES/specs/$MISFIT"
  "$FIXTURES/board/widgetchip.spec.md" "$FIXTURES/board/$BOARD_MISFIT"
  "$FIXTURES/board/widgetchip-src-overlay.spec.md")
if [ -n "$BOARD_FIT" ]; then
  needed+=("$FIXTURES/board/$BOARD_FIT")
fi
for f in "${needed[@]}"; do
  if [ ! -f "$f" ]; then
    echo "missing precondition: $f (is $dl a driver-lab checkout at the pinned commit?)" >&2
    exit 3
  fi
done
if [ ! -f specs/board-specs.yaml ]; then
  echo "missing precondition: specs/board-specs.yaml (run from the top of the repository)" >&2
  exit 3
fi
# ${further[@]+...} keeps an empty array from tripping set -u on bash before 4.4.
for r in ${further[@]+"${further[@]}"}; do
  if [ ! -f "$r/board-specs.yaml" ]; then
    echo "missing precondition: $r/board-specs.yaml (a further root must be a spec root)" >&2
    exit 3
  fi
done

check_specs() {
  local ctx=() r
  for r in ${further[@]+"${further[@]}"}; do
    ctx+=(--context-root "$r")
  done
  echo "== spec_check.py specs ${ctx[*]+${ctx[*]} }--require-license"
  python3 "$SPEC_CHECK" specs ${ctx[@]+"${ctx[@]}"} --require-license
}

check_anchors() {
  local n=0 failed=0 spec
  while IFS= read -r -d '' spec; do
    n=$((n + 1))
    echo "== anchor_check.py $spec --root specs --require-license"
    python3 "$ANCHOR_CHECK" "$spec" --root specs --require-license || failed=$((failed + 1))
  done < <(find specs -name '*-spec.md' -print0 | sort -z)
  # Board specs with [src] facts: their resources.repos entries are the pins (SPEC-FORMAT.md,
  # "Facts read from source"), so anchor_check.py gates them as it gates peripheral specs.
  local boards=0 cache="" repos line
  if [ "${RESOLVE_SRC:-0}" = 1 ]; then
    cache=$(mktemp -d)
  fi
  while IFS= read -r -d '' spec; do
    if grep -q '\[src:' "$spec"; then
      boards=$((boards + 1))
      repos=()
      if [ -n "$cache" ]; then
        while IFS= read -r line; do
          repos+=(--repo "$line")
        done < <(python3 "$FETCH_PINS" "$spec" "$cache" --limit-mb "${SRC_FETCH_LIMIT_MB:-50}")
      fi
      echo "== anchor_check.py $spec --root specs --require-license ${repos[*]+${repos[*]}}"
      python3 "$ANCHOR_CHECK" "$spec" --root specs --require-license ${repos[@]+"${repos[@]}"} \
        || failed=$((failed + 1))
    fi
  done < <(find specs -name '*.spec.md' -print0 | sort -z)
  if [ -n "$cache" ]; then
    rm -rf "$cache"
  fi
  echo "anchors: $n peripheral spec(s) and $boards board spec(s) with [src:] anchors checked, $failed failed"
  # Board specs (*.spec.md) are spec_check.py's, verification records (*.verify.md) its too.
  # Any other Markdown under specs/ would be checked by nothing: a misnamed peripheral spec.
  local stray=0
  while IFS= read -r -d '' spec; do
    echo "error: $spec: not checked by anything; name a peripheral spec <device>-spec.md, a board spec <id>.spec.md"
    stray=$((stray + 1))
  done < <(find specs -name '*.md' ! -name '*-spec.md' ! -name '*.spec.md' ! -name '*.verify.md' \
    ! -name README.md -print0 | sort -z)
  [ "$failed" -eq 0 ] && [ "$stray" -eq 0 ]
}

# expect <exit code> <required output line, an extended regex, or ""> <label> <command>...
expect() {
  local want=$1 needle=$2 label=$3 out rc=0
  shift 3
  out=$("$@" 2>&1) || rc=$?
  printf '%s\n' "$out" | sed 's/^/    | /'
  if [ "$rc" -ne "$want" ]; then
    echo "self-test FAILED: $label exited $rc, expected $want"
    return 1
  fi
  if [ -n "$needle" ]; then
    if ! grep -qE -- "$needle" <<<"$out"; then
      echo "self-test FAILED: $label exited $rc but no output line matches '$needle'"
      return 1
    fi
    echo "self-test: $label failed as required (exit $rc) with:"
    grep -E -- "$needle" <<<"$out" | sed 's/^/    /'
  else
    echo "self-test: $label passed (exit $rc)"
  fi
}

# A temporary root holding a copy of a marker and the given fixture files.
make_root() {
  local dir=$1 marker=$2
  shift 2
  mkdir -p "$dir"
  cp "$marker" "$dir/board-specs.yaml"
  local f
  for f in "$@"; do
    if [ -n "$f" ]; then
      cp "$f" "$dir/"
    fi
  done
}

self_test() {
  local board_fit=""
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  if [ -n "$BOARD_FIT" ]; then
    board_fit=$FIXTURES/board/$BOARD_FIT
  fi

  echo "== self-test: anchor gate, this repository's marker with $FIT (fit) and $MISFIT (misfit)"
  make_root "$tmp/anchors" specs/board-specs.yaml "$FIXTURES/specs/$FIT" "$FIXTURES/specs/$MISFIT"
  expect 0 "" "fit $FIT" \
    python3 "$ANCHOR_CHECK" "$tmp/anchors/$FIT" --root "$tmp/anchors" --require-license
  expect 1 "^ERROR L[0-9]+: license gate: .* does not accept \\(accepts: " "misfit $MISFIT" \
    python3 "$ANCHOR_CHECK" "$tmp/anchors/$MISFIT" --root "$tmp/anchors" --require-license

  echo "== self-test: anchor gate, ISC and 0BSD sources (fit), made from bsd-spec.md with the pin's license replaced"
  for lic in ISC 0BSD; do
    make_root "$tmp/$lic" specs/board-specs.yaml
    sed "s/BSD-3-Clause/$lic/g" "$FIXTURES/specs/bsd-spec.md" > "$tmp/$lic/$lic-spec.md"
    expect 0 "" "fit $lic-spec.md" \
      python3 "$ANCHOR_CHECK" "$tmp/$lic/$lic-spec.md" --root "$tmp/$lic" --require-license
  done

  echo "== self-test: board-spec gate, widgetchip.spec.md with ${BOARD_FIT:-no overlay} (fit) and $BOARD_MISFIT (misfit)"
  make_root "$tmp/board-fit" specs/board-specs.yaml "$FIXTURES/board/widgetchip.spec.md" "$board_fit"
  expect 0 "" "fit widgetchip.spec.md ${BOARD_FIT}" \
    python3 "$SPEC_CHECK" "$tmp/board-fit" --require-license
  make_root "$tmp/board-misfit" specs/board-specs.yaml "$FIXTURES/board/widgetchip.spec.md" \
    "$FIXTURES/board/$BOARD_MISFIT"
  expect 1 "^error: .*: license gate: repos entry " "misfit $BOARD_MISFIT" \
    python3 "$SPEC_CHECK" "$tmp/board-misfit" --require-license

  echo "== self-test: a [src] fact read from BSD-3-Clause source (widgetchip-src-overlay.spec.md), $([ "$SRC_FIT" = 1 ] && echo fit || echo misfit)"
  make_root "$tmp/src" specs/board-specs.yaml "$FIXTURES/board/widgetchip.spec.md" \
    "$FIXTURES/board/widgetchip-src-overlay.spec.md"
  if [ "$SRC_FIT" = 1 ]; then
    expect 0 "" "fit widgetchip-src-overlay.spec.md (spec_check)" \
      python3 "$SPEC_CHECK" "$tmp/src" --require-license
    expect 0 "" "fit widgetchip-src-overlay.spec.md (anchor_check)" \
      python3 "$ANCHOR_CHECK" "$tmp/src/widgetchip-src-overlay.spec.md" --root "$tmp/src" --require-license
  else
    expect 1 "^error: .*: license gate: \\[src\\] cites repos entry 'tools' " \
      "misfit widgetchip-src-overlay.spec.md (spec_check)" \
      python3 "$SPEC_CHECK" "$tmp/src" --require-license
    expect 1 "^ERROR L[0-9]+: license gate: .* does not accept \\(accepts: " \
      "misfit widgetchip-src-overlay.spec.md (anchor_check)" \
      python3 "$ANCHOR_CHECK" "$tmp/src/widgetchip-src-overlay.spec.md" --root "$tmp/src" --require-license
  fi

  if [ "${#further[@]}" -gt 0 ]; then
    echo "== self-test: an overlay here resolves against a spec in ${further[0]} only when both roots are read"
    make_root "$tmp/other" "${further[0]}/board-specs.yaml" "$FIXTURES/board/widgetchip.spec.md"
    make_root "$tmp/overlay" specs/board-specs.yaml "$FIXTURES/board/widgetchip-bsd-overlay.spec.md"
    expect 1 "^error: .*: overlays 'widgetchip' resolves to nothing$" "overlay without the second root" \
      python3 "$SPEC_CHECK" "$tmp/overlay" --require-license
    expect 0 "" "overlay with the second root" \
      python3 "$SPEC_CHECK" "$tmp/overlay" "$tmp/other" --require-license
  fi
  echo "self-test: passed"
}

case "$step" in
  specs) check_specs ;;
  anchors) check_anchors ;;
  self-test) self_test ;;
  all)
    check_specs
    check_anchors
    self_test
    ;;
  *) usage ;;
esac
