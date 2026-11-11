#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
engine_bin="${GODOT_BIN:-$project_root/.godot/cloud-tools/godot-4.7.2}"
if [[ ! -x "$engine_bin" ]]; then
  echo "Godot not found. Run: bash tools/cloud/setup.sh" >&2
  exit 1
fi

check_dir="$(mktemp -d)"
trap 'rm -rf -- "$check_dir"' EXIT
mkdir -p -- "$check_dir/user-data" "$check_dir/config" "$check_dir/cache"

run_check() {
  local check_name="$1"
  shift
  local check_log="$check_dir/$check_name.log"
  local command_status=0
  XDG_DATA_HOME="$check_dir/user-data" \
    XDG_CONFIG_HOME="$check_dir/config" \
    XDG_CACHE_HOME="$check_dir/cache" "$engine_bin" \
    --headless --path "$project_root" --rendering-method gl_compatibility \
    "$@" >"$check_log" 2>&1 || command_status=$?
  cat -- "$check_log"
  if [[ "$command_status" -ne 0 ]]; then
    echo "$check_name failed (exit $command_status)." >&2
    return "$command_status"
  fi
  if grep -Eq 'SCRIPT ERROR:|(^|[[:space:]])ERROR:' "$check_log"; then
    echo "$check_name reported Godot errors; inspect the output above." >&2
    return 1
  fi
}

run_check import --editor --import
run_check startup --quit-after 120
echo "Resource import and headless startup passed. Visual and input review remain separate."
