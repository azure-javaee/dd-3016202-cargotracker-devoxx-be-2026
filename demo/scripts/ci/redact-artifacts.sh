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
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
check_only = sys.argv[2] == "true"
directories = [pathlib.Path(value).resolve() for value in sys.argv[3:]]


def display_path(path):
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return path.name


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
forbidden_attributes = {
    "url.query",
    "url.full",
    "http.url",
    "http.target",
    "db.statement",
    "db.connection_string",
    "db.user",
    "http.request.body",
    "http.response.body",
    "http.request.header.authorization",
    "http.request.header.cookie",
    "http.response.header.set_cookie",
}

files = []
for directory in directories:
    if not directory.is_dir():
        raise SystemExit(f"redaction input directory missing: {directory}")
    files.extend(path for path in directory.rglob("*") if path.is_file())
if not files:
    raise SystemExit("redaction inputs contain no files")

findings = []
artifact_findings = []
redactions = 0


def inspect_json(value, path):
    if isinstance(value, dict):
        attribute_key = value.get("key")
        if isinstance(attribute_key, str) and attribute_key.lower() in forbidden_attributes:
            artifact_findings.append(
                f"{display_path(path)}: forbidden field {attribute_key}"
            )
        for child in value.values():
            inspect_json(child, path)
    elif isinstance(value, list):
        for child in value:
            inspect_json(child, path)


for path in sorted(files):
    try:
        content = path.read_bytes()
    except OSError as error:
        raise SystemExit(f"unable to read redaction input {path}: {error}") from error
    if b"ABC123" in content:
        artifact_findings.append(f"{display_path(path)}: seeded cargo identifier")
    if path.suffix.lower() == ".json":
        line_documents = []
        all_lines_are_json = True
        for line in content.splitlines():
            if not line.strip():
                continue
            try:
                document = json.loads(line)
            except (UnicodeDecodeError, json.JSONDecodeError):
                all_lines_are_json = False
                break
            if not isinstance(document, (dict, list)):
                all_lines_are_json = False
                break
            line_documents.append(document)
        if line_documents and all_lines_are_json:
            for document in line_documents:
                inspect_json(document, path)
        else:
            try:
                inspect_json(json.loads(content), path)
            except (UnicodeDecodeError, json.JSONDecodeError):
                pass
    changed = content
    for pattern in secret_patterns:
        if check_only:
            if pattern.search(changed):
                findings.append(display_path(path))
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
                findings.append(display_path(path))
                break

if findings:
    for name in findings:
        print(f"secret-like content found in {name}", file=sys.stderr)

if artifact_findings:
    for finding in artifact_findings:
        print(f"artifact redaction failed: {finding}", file=sys.stderr)

if findings or artifact_findings:
    raise SystemExit(1)

if check_only:
    print(f"secret-pattern check passed: {len(files)} files scanned")
else:
    print(f"redaction check passed: {len(files)} files scanned, {redactions} values redacted")
PY
