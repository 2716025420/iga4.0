#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
engine_bin="${GODOT_BIN:-$project_root/.godot/cloud-tools/godot-4.7.2}"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/data" "$test_dir/config" "$test_dir/cache"
runtime_args=(--headless)
user_args=()
if [[ -n "${P5_CAPTURE_DIR:-}" ]]; then
 runtime_args=(--display-driver x11 --resolution "${P5_RESOLUTION:-1920x1080}")
 user_args=(-- "--captures=$P5_CAPTURE_DIR")
fi
status=0
XDG_DATA_HOME="$test_dir/data" XDG_CONFIG_HOME="$test_dir/config" XDG_CACHE_HOME="$test_dir/cache" \
 timeout 300s "$engine_bin" "${runtime_args[@]}" --path "$project_root" --rendering-method gl_compatibility --audio-driver Dummy \
 "${P5_TEST_SCENE:-res://tools/tests/p5_regions.tscn}" "${user_args[@]}" > "$test_dir/results.log" 2>&1 || status=$?
cat "$test_dir/results.log"
if [[ "$status" -ne 0 ]] || rg -q 'SCRIPT ERROR:|(^|[[:space:]])ERROR:|FAIL:' "$test_dir/results.log"; then exit 1; fi
rg -q 'P5_RESULT|HOME_OBJECT_RESULT|SCENE_RESET_RESULT|TERMINAL_RESULT' "$test_dir/results.log"
