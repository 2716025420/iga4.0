"""Run production-scene regressions with disposable player data and strict log checks."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import struct
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
SUITES = {
    "regions": ("p5_regions", "P5_RESULT"),
    "home": ("home_objects", "HOME_OBJECT_RESULT"),
    "scenes": ("scene_reset", "SCENE_RESET_RESULT"),
    "terminal": ("student_terminal", "TERMINAL_RESULT"),
}
ERROR = re.compile(r"SCRIPT ERROR:|(?:^|\s)ERROR:|FAIL:", re.MULTILINE)


def check_indentation() -> list[str]:
    errors = []
    for folder in ["scripts", "tools/tests"]:
        for file in (ROOT / folder).rglob("*.gd"):
            styles = set()
            multiline = None
            for line_no, line in enumerate(file.read_text(encoding="utf-8-sig").splitlines(), 1):
                if multiline:
                    if line.count(multiline) % 2:
                        multiline = None
                    continue
                stripped = line.lstrip()
                prefix = line[:len(line) - len(stripped)]
                if stripped and not stripped.startswith("#") and prefix:
                    styles.add("tabs" if prefix.startswith("\t") else "spaces")
                    if "\t" in prefix and " " in prefix:
                        errors.append(f"{file.relative_to(ROOT)}:{line_no}: mixed tab/space indentation")
                for delimiter in ['"""', "'''" ]:
                    if line.count(delimiter) % 2:
                        multiline = delimiter
                        break
            if len(styles) > 1:
                errors.append(f"{file.relative_to(ROOT)}: indentation style changes within the file")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN"), required=not os.environ.get("GODOT_BIN"))
    parser.add_argument("--suite", choices=[*SUITES, "all"], default="all")
    parser.add_argument("--resolution", help="Render using the native window driver, e.g. 1600x900; default is headless")
    parser.add_argument("--captures", type=Path, help="Local output directory; requires --resolution")
    parser.add_argument("--fullscreen", action="store_true", help="Use the monitor's full canvas to avoid desktop window-size clamping")
    parser.add_argument("--output", type=Path, default=ROOT / ".godot/test-results")
    args = parser.parse_args()
    if args.captures and not args.resolution:
        parser.error("--captures requires --resolution")
    if args.fullscreen and not args.resolution:
        parser.error("--fullscreen requires --resolution")
    args.output.mkdir(parents=True, exist_ok=True)
    indentation_errors = check_indentation()
    if indentation_errors:
        print(json.dumps({"preflight_passed": False, "indentation_errors": indentation_errors}, ensure_ascii=False, indent=2))
        return 1
    reports = []
    for name in SUITES if args.suite == "all" else [args.suite]:
        scene, marker = SUITES[name]
        with tempfile.TemporaryDirectory(prefix="iga-tests-") as temp:
            env = os.environ.copy()
            for key, folder in {"APPDATA": "appdata", "LOCALAPPDATA": "localappdata", "XDG_DATA_HOME": "data", "XDG_CONFIG_HOME": "config", "XDG_CACHE_HOME": "cache"}.items():
                path = Path(temp, folder)
                path.mkdir()
                env[key] = str(path)
            command = [args.godot, "--path", str(ROOT), "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--quit-after", "12000"]
            command += ["--resolution", args.resolution] if args.resolution else ["--headless"]
            command += [f"res://tools/tests/{scene}.tscn"]
            user_args = ["--fullscreen-capture"] if args.fullscreen else []
            if args.captures:
                user_args += ["--captures=" + str((args.captures / name).resolve())]
            if user_args:
                command += ["--", *user_args]
            started = time.monotonic()
            try:
                result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=300)
                log, exit_code = result.stdout + result.stderr, result.returncode
            except subprocess.TimeoutExpired as error:
                log = "TEST TIMEOUT after 300 seconds\n" + (error.stdout or b"").decode("utf-8", errors="replace") + (error.stderr or b"").decode("utf-8", errors="replace")
                exit_code = 124
            (args.output / f"{name}.log").write_text(log, encoding="utf-8")
            matches = re.findall(r"^" + marker + r" (.+)$", log, re.MULTILINE)
            detail = json.loads(matches[-1]) if matches else {}
            passed = exit_code == 0 and bool(detail) and not detail.get("failures") and not ERROR.search(log)
            dimensions = set()
            if args.captures:
                for file in (args.captures / name).glob("*.png"):
                    with file.open("rb") as handle:
                        dimensions.add(struct.unpack(">II", handle.read(24)[16:24]))
                expected = tuple(map(int, args.resolution.split("x")))
                passed = passed and dimensions == {expected}
                if dimensions != {expected}:
                    print(f"CAPTURE SIZE MISMATCH: requested {expected}; actual {dimensions}", flush=True)
            report = {"suite": name, "passed": passed, "exit_code": exit_code, "seconds": round(time.monotonic() - started, 2), **detail}
            if dimensions:
                report["capture_pixels"] = sorted(dimensions)
            reports.append(report)
            print(json.dumps(report, ensure_ascii=False), flush=True)
            if not passed:
                print(log, flush=True)
    (args.output / "results.json").write_text(json.dumps(reports, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0 if all(report["passed"] for report in reports) else 1


if __name__ == "__main__":
    raise SystemExit(main())
