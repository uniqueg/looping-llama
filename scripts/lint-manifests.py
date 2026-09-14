#!/usr/bin/env python3
import glob
import sys

try:
    import tomllib
except ModuleNotFoundError:
    try:
        import tomli as tomllib
    except ModuleNotFoundError:
        print("[WARN] tomllib not found; skipping deep TOML validation.")
        sys.exit(0)

manifest_files = glob.glob("config/**/*.toml", recursive=True)
for path in manifest_files:
    try:
        with open(path, "rb") as f:
            tomllib.load(f)
    except Exception as e:
        print(f"[FAIL] Invalid TOML: {path}\n  {e}", file=sys.stderr)
        sys.exit(1)

print(f"[OK] Validated {len(manifest_files)} TOML manifests.")
