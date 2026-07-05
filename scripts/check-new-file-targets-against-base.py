#!/usr/bin/env python3
"""Fail when final-state patch target shape disagrees with the base ref."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def _read_base_ref(payload_dir: Path) -> str:
    base_ref_file = payload_dir / "base.ref"
    for line in base_ref_file.read_text(errors="replace").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        if key.strip() == "base":
            return value.strip()
    raise SystemExit(f"ERROR: {base_ref_file} does not contain a base= value")


def _series_entries(payload_dir: Path) -> list[str]:
    series_file = payload_dir / "series"
    entries: list[str] = []
    for line in series_file.read_text(errors="replace").splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            entries.append(stripped)
    return entries


def _patch_target(patch_path: Path) -> tuple[str, bool]:
    text = patch_path.read_text(errors="replace")
    is_new_file = "new file mode" in text or "--- /dev/null" in text
    for line in text.splitlines():
        if line.startswith("+++ b/"):
            return line[6:], is_new_file
    raise SystemExit(f"ERROR: patch has no +++ b/ target: {patch_path}")


def _exists_at_ref(checkout: Path, ref: str, target: str) -> bool:
    result = subprocess.run(
        ["git", "-C", str(checkout), "cat-file", "-e", f"{ref}:{target}"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check that payload patches target files with the expected base-ref shape."
    )
    parser.add_argument("checkout", type=Path, help="Hermes checkout containing the base ref")
    parser.add_argument("payload_dir", type=Path, help="patches/hermes-safe-fetch-context directory")
    parser.add_argument("--base-ref", help="Base ref to check; defaults to payload base.ref")
    args = parser.parse_args()

    checkout = args.checkout.resolve()
    payload_dir = args.payload_dir.resolve()
    base_ref = args.base_ref or _read_base_ref(payload_dir)

    bad_new: list[str] = []
    bad_missing: list[str] = []
    for entry in _series_entries(payload_dir):
        patch_path = payload_dir / entry
        target, is_new_file = _patch_target(patch_path)
        exists = _exists_at_ref(checkout, base_ref, target)
        if is_new_file and exists:
            bad_new.append(f"{entry} -> {target}")
        elif not is_new_file and not exists:
            bad_missing.append(f"{entry} -> {target}")

    if bad_new or bad_missing:
        if bad_new:
            print(
                f"ERROR: new-file payload fragments target files already present at {base_ref}:",
                file=sys.stderr,
            )
            for item in bad_new:
                print(f"  {item}", file=sys.stderr)
        if bad_missing:
            print(
                f"ERROR: existing-file payload fragments target files absent at {base_ref}:",
                file=sys.stderr,
            )
            for item in bad_missing:
                print(f"  {item}", file=sys.stderr)
        return 1

    print(f"patch target/base-ref shape check ok at {base_ref}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
