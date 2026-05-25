#!/usr/bin/env bash

set -euo pipefail

REPO_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)"
SCRIPT_DIR="$REPO_BIN"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/runtime.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/commands.sh"

pass=0
fail=0
tmpdirs=()

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [ "$expected" = "$actual" ]; then
    printf '  ✓ %s\n' "$message"
    pass=$((pass + 1))
  else
    printf '  ✗ %s\n    期望: %s\n    实际: %s\n' "$message" "$expected" "$actual"
    fail=$((fail + 1))
  fi
}

mktempdir() {
  local dir
  dir=$(mktemp -d)
  tmpdirs+=("$dir")
  printf '%s\n' "$dir"
}

cleanup() {
  if [ "${tmpdirs+x}" != x ]; then
    return
  fi

  local dir
  for dir in "${tmpdirs[@]}"; do
    rm -rf "$dir"
  done
}
trap cleanup EXIT

printf '=== shell-hook help guard ===\n'

fake_root=$(mktempdir)
cat > "$fake_root/wt" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}|${2:-}" in
  -h\||--help\||help\|)
    printf '%s\n' "$script_dir/help-target"
    ;;
  rm\|--help|add\|--help|path\|--help)
    printf '%s\n' "$script_dir/help-target"
    ;;
  rm\|demo|add\|demo|path\|demo|demo\|)
    printf '%s\n' "$script_dir/jump-target"
    ;;
  *)
    printf '%s\n' "$script_dir/default-target"
    ;;
esac
EOF
chmod +x "$fake_root/wt"
mkdir -p "$fake_root/help-target" "$fake_root/jump-target" "$fake_root/default-target"

original_script_dir="$SCRIPT_DIR"
SCRIPT_DIR="$fake_root"
hook="$(cmd_shell_hook bash)"
SCRIPT_DIR="$original_script_dir"

workspace=$(mktempdir)
mkdir -p "$workspace/start"
cd "$workspace/start"

eval "$hook"

before_pwd=$(pwd)
rm_help_output="$(wt rm --help)"
after_rm_help_pwd=$(pwd)
assert_equals "$fake_root/help-target" "$rm_help_output" 'wt rm --help 保留原始输出'
assert_equals "$before_pwd" "$after_rm_help_pwd" 'wt rm --help 不触发 auto-cd'

root_help_output="$(wt --help)"
after_root_help_pwd=$(pwd)
assert_equals "$fake_root/help-target" "$root_help_output" 'wt --help 保留原始输出'
assert_equals "$before_pwd" "$after_root_help_pwd" 'wt --help 不触发 auto-cd'

short_help_output="$(wt -h)"
after_short_help_pwd=$(pwd)
assert_equals "$fake_root/help-target" "$short_help_output" 'wt -h 保留原始输出'
assert_equals "$before_pwd" "$after_short_help_pwd" 'wt -h 不触发 auto-cd'

wt rm demo > /dev/null
assert_equals "$fake_root/jump-target" "$(pwd)" 'wt rm demo 仍会根据路径输出自动切换目录'

printf '\n'
if [ "$fail" -eq 0 ]; then
  printf '✅ shell-hook 测试全部通过，共 %d 项。\n' "$pass"
else
  printf '❌ shell-hook 测试存在失败：%d 通过，%d 失败。\n' "$pass" "$fail"
  exit 1
fi
