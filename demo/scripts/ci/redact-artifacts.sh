#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
check_only=false
if [[ "${1:-}" == "--check-only" ]]; then
  check_only=true
  shift
fi
if [[ "$#" -eq 0 ]]; then
  echo "usage: redact-artifacts.sh [--check-only] <artifact-directory>..." >&2
  exit 2
fi

python3 - "$root" "$check_only" "$@" <<'PY'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
check_only = sys.argv[2] == "true"
directories = [pathlib.Path(value).resolve() for value in sys.argv[3:]]
credential = re.compile(
    rb"""(?ix)
    (\b(?:password|passwd|token|secret|authorization|api[_-]?key|
    client[_-]?secret|access[_-]?key|connectionstring)\b
    ["']?\s*[:=]\s*["']?)(?!<REDACTED>)([^\s,"'}]+)
    """
)
secret_patterns = [
    credential,
    re.compile(rb"\bgh[pousr]_[A-Za-z0-9]{30,}\b"),
    re.compile(rb"\bgithub_pat_[A-Za-z0-9_]{30,}\b"),
    re.compile(rb"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(rb"(AccountKey=)([A-Za-z0-9+/=]{16,})"),
]

files = []
for directory in directories:
    if not directory.is_dir():
        raise SystemExit(f"redaction input directory missing: {directory}")
    files.extend(path for path in directory.rglob("*") if path.is_file())
if not files:
    raise SystemExit("redaction inputs contain no files")

findings = []
redactions = 0
for path in sorted(files):
    try:
        content = path.read_bytes()
    except OSError as error:
        raise SystemExit(f"unable to read redaction input {path}: {error}") from error
    changed = content
    for pattern in secret_patterns:
        if check_only:
            if pattern.search(changed):
                findings.append(path.relative_to(root).as_posix())
                break
            continue
        if pattern is credential or pattern is secret_patterns[-1]:
            changed, count = pattern.subn(lambda match: match.group(1) + b"<REDACTED>", changed)
        else:
            changed, count = pattern.subn(b"<REDACTED>", changed)
        redactions += count
    if not check_only and changed != content:
        path.write_bytes(changed)
    if not check_only:
        for pattern in secret_patterns:
            if pattern.search(changed):
                findings.append(path.relative_to(root).as_posix())
                break

if findings:
    for name in findings:
        print(f"secret-like content found in {name}", file=sys.stderr)
    raise SystemExit(1)

if check_only:
    print(f"secret-pattern check passed: {len(files)} files scanned")
else:
    print(f"redaction check passed: {len(files)} files scanned, {redactions} values redacted")
PY
