#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)"
# shellcheck source=../bin/lib/runtime.sh
source "$SCRIPT_DIR/lib/runtime.sh"

pass=0
fail=0

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

assert_empty() {
  local actual="$1"
  local message="$2"

  if [ -z "$actual" ]; then
    printf '  ✓ %s\n' "$message"
    pass=$((pass + 1))
  else
    printf '  ✗ %s\n    实际: %s\n' "$message" "$actual"
    fail=$((fail + 1))
  fi
}

printf '=== 精确匹配分支删除保护 ===\n'

validate_removable_worktree_branch "ui9083" "wt-feat/ui9083" "wt-feat/" || true
assert_equals "wt-feat/ui9083" "$WT_VALIDATED_REMOVE_BRANCH" '标准 worktree 分支允许删除'
assert_empty "$WT_REMOVE_BRANCH_REASON" '标准 worktree 分支不记录跳过原因'

validate_removable_worktree_branch "ui9083" "dev" "wt-feat/" || true
assert_empty "$WT_VALIDATED_REMOVE_BRANCH" '受保护分支不会被加入删除列表'
assert_equals "protected" "$WT_REMOVE_BRANCH_REASON" 'dev 被识别为受保护分支'
assert_equals "wt-feat/ui9083" "$WT_REMOVE_BRANCH_EXPECTED" '受保护分支仍保留期望分支名'

validate_removable_worktree_branch "ui9083" "feature/ui9083" "wt-feat/" || true
assert_empty "$WT_VALIDATED_REMOVE_BRANCH" '分支名前缀不匹配时不会删除'
assert_equals "mismatch" "$WT_REMOVE_BRANCH_REASON" '前缀不匹配记录 mismatch'

validate_removable_worktree_branch "ui9083" "" "wt-feat/" || true
assert_empty "$WT_VALIDATED_REMOVE_BRANCH" '无法确认当前分支时不会猜测删除目标'
assert_equals "missing" "$WT_REMOVE_BRANCH_REASON" '缺失分支记录 missing'

printf '\n'
if [ "$fail" -eq 0 ]; then
  printf '✅ rm 分支保护测试全部通过，共 %d 项。\n' "$pass"
else
  printf '❌ rm 分支保护测试存在失败：%d 通过，%d 失败。\n' "$pass" "$fail"
  exit 1
fi
