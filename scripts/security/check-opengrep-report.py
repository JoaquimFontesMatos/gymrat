#!/usr/bin/env python3
"""Fail when OpenGrep reports analysis errors without printing source snippets."""
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    report = json.load(handle)

errors = report.get("errors", [])
if errors:
    print(f"OpenGrep reported {len(errors)} analysis error(s); see report.", file=sys.stderr)
    sys.exit(1)
