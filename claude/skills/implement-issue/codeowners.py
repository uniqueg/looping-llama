#!/usr/bin/env python3
"""Print the CODEOWNERS entries that cover the files changed since BASE.

Usage: codeowners.py BASE        (e.g. origin/main; run inside the repo/worktree)

Reads CODEOWNERS from BASE (GitHub uses the base branch's file), from the first of
.github/CODEOWNERS, CODEOWNERS, docs/CODEOWNERS. Matching follows GitHub's rules:
gitignore-style patterns, last matching line wins, `dir/*` matches direct children only.
"""
import re
import subprocess
import sys

LOCATIONS = (".github/CODEOWNERS", "CODEOWNERS", "docs/CODEOWNERS")


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True)


def to_regex(pattern):
    dir_only = pattern.endswith("/")
    body = pattern.strip("/")
    anchored = pattern.startswith("/") or "/" in body
    out, i = "", 0
    while i < len(body):
        if body.startswith("**/", i):
            out, i = out + "(?:.*/)?", i + 3
        elif body.startswith("**", i):
            out, i = out + ".*", i + 2
        elif body[i] == "*":
            out, i = out + "[^/]*", i + 1
        elif body[i] == "?":
            out, i = out + "[^/]", i + 1
        else:
            out, i = out + re.escape(body[i]), i + 1
    prefix = "^" if anchored else "^(?:.*/)?"
    if dir_only:
        suffix = "/.*$"
    elif body.endswith("/*"):
        suffix = "$"  # GitHub: `docs/*` does not match docs/sub/file
    else:
        suffix = "(?:/.*)?$"
    return re.compile(prefix + out + suffix)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__.strip().splitlines()[2])
    base = sys.argv[1]
    for loc in LOCATIONS:
        shown = git("show", f"{base}:{loc}")
        if shown.returncode == 0:
            break
    else:
        print(f"No CODEOWNERS file on {base} (checked {', '.join(LOCATIONS)}).")
        return
    rules = []
    for line in shown.stdout.splitlines():
        line = line.split(" #")[0].strip()
        if line and not line.startswith("#"):
            pattern, *owners = line.split()
            rules.append((to_regex(pattern), pattern, owners))
    diff = git("diff", "--name-only", f"{base}...HEAD")
    if diff.returncode != 0:
        sys.exit(diff.stderr.strip())
    everyone = set()
    print(f"CODEOWNERS ({base}:{loc}) for changed paths:")
    for path in diff.stdout.split():
        match = next(((p, o) for rx, p, o in reversed(rules) if rx.match(path)), None)
        if match and match[1]:
            everyone.update(match[1])
            print(f"  {path}: {' '.join(match[1])}   [{match[0]}]")
        else:
            print(f"  {path}: (no owner)")
    print("Owners to expect as reviewers: " + (" ".join(sorted(everyone)) or "none"))


if __name__ == "__main__":
    main()
