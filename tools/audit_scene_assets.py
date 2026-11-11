"""Verify a recorded scene asset/archival manifest and current runtime references."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--art", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--verify-local-archive", action="store_true", help="Optional: ignored local archives are absent on a clean clone")
    args = parser.parse_args()
    errors = []
    art = json.loads(args.art.read_text(encoding="utf-8"))
    archive = json.loads(args.archive.read_text(encoding="utf-8"))
    for row in art["assets"]:
        file = ROOT / row["path"]
        if not file.is_file() or digest(file) != row["sha256"]:
            errors.append("missing/changed scene art: " + row["path"])
    originals = json.loads((ROOT / "docs/2026-10-24/p5-delivery/concepts/ORIGINALS.json").read_text(encoding="utf-8"))
    for row in originals["originals"]:
        file = ROOT / row["path"]
        if not file.is_file() or digest(file) != row["sha256"]:
            errors.append("changed original Home concept: " + row["path"])
    sources = [ROOT / "project.godot", *ROOT.glob("*.tres"), *ROOT.glob("*.tscn")]
    for directory in ["scripts", "scenes", "data", "tools/tests"]:
        sources += [p for p in (ROOT / directory).rglob("*") if p.suffix in [".gd", ".tscn", ".tres", ".gdshader", ".json"]]
    texts = {p.relative_to(ROOT).as_posix(): p.read_text(encoding="utf-8-sig") for p in sources}
    for name, body in texts.items():
        if "res://assets/ui/phase_two/" in body or re.search(r"\bPhaseTwoSkin\.", body):
            errors.append("retired UI dependency: " + name)
        for target in re.findall(r'''["']res://([^"'\r\n]+)["']''', body):
            if "%" not in target and Path(target).suffix and not (ROOT / target).exists():
                errors.append(f"missing resource in {name}: {target}")
    for row in archive["files"]:
        if (ROOT / row["from"]).exists():
            errors.append("retired file still active: " + row["from"])
        for name, body in texts.items():
            if "res://" + row["from"] in body or (row.get("uid") and row["uid"] in body):
                errors.append(f"retired path/UID referenced in {name}: {row['from']}")
        if args.verify_local_archive:
            local = ROOT / row["to"]
            if not local.is_file() or digest(local) != row["sha256"]:
                errors.append("local archive mismatch: " + row["from"])
    report = {"art_assets": len(art["assets"]), "preserved_originals": len(originals["originals"]), "archived_files": len(archive["files"]), "runtime_sources": len(texts), "errors": errors}
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
