#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
engine_dir="$project_root/.godot/cloud-tools"
engine_bin="$engine_dir/godot-4.7.2"

if [[ "$(uname -s)" != Linux ]]; then
  echo "This installer targets Linux cloud environments. Use Godot 4.7.2 on other systems." >&2
  exit 1
fi

case "$(uname -m)" in
  x86_64)
    architecture=x86_64
    expected_sha512=9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65
    ;;
  aarch64|arm64)
    architecture=arm64
    expected_sha512=dd59918da086bd49bde2f5450b5e567ff8650cbde9abbd7b8f4ca1197ff8c609baa38834666d032deafb47099078d7822279e2a0e06e5665745468f26533e7e2
    ;;
  *) echo "Unsupported Linux architecture: $(uname -m)" >&2; exit 1 ;;
esac

if [[ ! -x "$engine_bin" ]]; then
  command -v curl >/dev/null
  command -v python3 >/dev/null
  command -v sha512sum >/dev/null
  download_dir="$(mktemp -d)"
  trap 'rm -rf -- "$download_dir"' EXIT
  executable="Godot_v4.7.2-stable_linux.$architecture"
  archive_name="$executable.zip"
  curl --fail --location --retry 3 \
    "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/$archive_name" \
    --output "$download_dir/$archive_name"
  printf '%s  %s\n' "$expected_sha512" "$download_dir/$archive_name" | sha512sum --check --status
  mkdir -p -- "$engine_dir"
  python3 - "$download_dir/$archive_name" "$executable" "$engine_bin" <<'PY'
import pathlib
import shutil
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1]) as archive:
    with archive.open(sys.argv[2]) as source, open(sys.argv[3], "wb") as target:
        shutil.copyfileobj(source, target)
pathlib.Path(sys.argv[3]).chmod(0o755)
PY
fi

engine_version="$("$engine_bin" --version)"
if [[ "$engine_version" != 4.7.2.stable.* ]]; then
  echo "Expected Godot 4.7.2 stable, received: $engine_version" >&2
  exit 1
fi
printf 'Installed Godot %s\n' "$engine_version"
bash "$project_root/tools/cloud/check.sh"
