# shellcheck shell=bash

lang_effective_code() {
  local code="$LANGUAGE"
  if [ -z "$code" ]; then
    code="$CONFIG_DEFAULT_LANGUAGE"
  fi
  printf '%s\n' "$code"
}

lang_display_name() {
  local code="${1:-}"
  case "$LANGUAGE" in
  zh)
    case "$code" in
    zh)
      printf '中文'
      ;;
    en)
      printf '英文'
      ;;
    *)
      printf '%s' "$code"
      ;;
    esac
    ;;
  *)
    case "$code" in
    zh)
      printf 'Chinese'
      ;;
    en)
      printf 'English'
      ;;
    *)
      printf '%s' "$code"
      ;;
    esac
    ;;
  esac
}

lang_store_global_value() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local code="$1"
  local stored
  stored=$(language_code_to_config_value "$code")
  config_set_in_file "$CONFIG_FILE_DEFAULT" "language" "$stored"
  LANGUAGE="$code"
}

lang_set_global_from_raw() {
  if [ $# -ne 1 ]; then
    die "$(msg lang_set_requires)"
  fi

  local raw="$1"
  local normalized
  if ! normalized=$(normalize_language "$raw" 2> /dev/null); then
    die "$(msg invalid_language "$raw")"
  fi

  lang_store_global_value "$normalized"
  return 0
}

lang_reset_global() {
  lang_store_global_value "$CONFIG_DEFAULT_LANGUAGE"
}

lang_print_current_value() {
  lang_effective_code
}

lang_show_current_message() {
  local code
  code=$(lang_effective_code)
  local label
  label=$(lang_display_name "$code")
  info "$(msg lang_current "$label" "$code")"
}

lang_set_with_feedback() {
  if lang_set_global_from_raw "$1"; then
    local code
    code=$(lang_effective_code)
    local label
    label=$(lang_display_name "$code")
    info "$(msg lang_set_success "$label" "$code")"
  fi
}

lang_reset_with_feedback() {
  lang_reset_global
  local code
  code=$(lang_effective_code)
  local label
  label=$(lang_display_name "$code")
  info "$(msg lang_reset_success "$label" "$code")"
}

lang_prompt_interactive() {
  prompt_init_ui
  if [ "$PROMPT_HAS_TTY" -ne 1 ]; then
    lang_print_current_value
    return
  fi

  local -a options=()
  options+=("$(msg lang_option_en_label)|en|$(msg lang_option_en_hint)")
  options+=("$(msg lang_option_zh_label)|zh|$(msg lang_option_zh_hint)")
  options+=("$(msg lang_option_reset_label)|__reset__|$(msg lang_option_reset_hint)")

  local default_index=0
  local current
  current=$(lang_effective_code)
  case "$current" in
  zh)
    default_index=1
    ;;
  en)
    default_index=0
    ;;
  *)
    default_index=0
    ;;
  esac

  local previous_assume="$PROMPT_ASSUME_DEFAULTS"
  PROMPT_ASSUME_DEFAULTS=0

  local selection
  if ! selection=$(prompt_choice "$(msg lang_prompt_select)" "$default_index" "${options[@]}"); then
    PROMPT_ASSUME_DEFAULTS="$previous_assume"
    die "$(msg aborted)"
  fi

  PROMPT_ASSUME_DEFAULTS="$previous_assume"

  case "$selection" in
  en | zh)
    lang_set_with_feedback "$selection"
    ;;
  __reset__)
    lang_reset_with_feedback
    ;;
  *)
    die "$(msg lang_unknown_command "$selection")"
    ;;
  esac
}

theme_effective_code() {
  local code="$LIST_THEME"
  if [ -z "$code" ]; then
    code="$CONFIG_DEFAULT_THEME"
  fi
  printf '%s\n' "$code"
}

theme_display_name() {
  case "${1:-}" in
  box)
    printf 'box'
    ;;
  sage)
    printf 'sage'
    ;;
  archer)
    printf 'archer'
    ;;
  *)
    printf '%s' "${1:-}"
    ;;
  esac
}

theme_store_global_value() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local code="$1"
  local stored
  stored=$(theme_code_to_config_value "$code")
  config_set_in_file "$CONFIG_FILE_DEFAULT" "theme" "$stored"
  LIST_THEME="$code"
}

theme_set_global_from_raw() {
  if [ $# -ne 1 ]; then
    die "$(msg theme_set_requires)"
  fi

  local raw="$1"
  local normalized
  if ! normalized=$(normalize_theme "$raw" 2> /dev/null); then
    die "$(msg invalid_theme "$raw")"
  fi

  theme_store_global_value "$normalized"
  return 0
}

theme_reset_global() {
  theme_store_global_value "$CONFIG_DEFAULT_THEME"
}

theme_print_current_value() {
  theme_effective_code
}

theme_show_current_message() {
  local code
  code=$(theme_effective_code)
  local label
  label=$(theme_display_name "$code")
  info "$(msg theme_current "$label" "$code")"
}

theme_set_with_feedback() {
  if theme_set_global_from_raw "$1"; then
    local code
    code=$(theme_effective_code)
    local label
    label=$(theme_display_name "$code")
    info "$(msg theme_set_success "$label" "$code")"
  fi
}

theme_reset_with_feedback() {
  theme_reset_global
  local code
  code=$(theme_effective_code)
  local label
  label=$(theme_display_name "$code")
  info "$(msg theme_reset_success "$label" "$code")"
}

theme_prompt_interactive() {
  prompt_init_ui
  if [ "$PROMPT_HAS_TTY" -ne 1 ]; then
    theme_print_current_value
    return
  fi

  local -a options=()
  options+=("$(msg theme_option_box_label)|box|$(msg theme_option_box_hint)")
  options+=("$(msg theme_option_sage_label)|sage|$(msg theme_option_sage_hint)")
  options+=("$(msg theme_option_archer_label)|archer|$(msg theme_option_archer_hint)")
  options+=("$(msg theme_option_reset_label)|__reset__|$(msg theme_option_reset_hint)")

  local default_index=0
  local current
  current=$(theme_effective_code)
  case "$current" in
  sage)
    default_index=1
    ;;
  archer)
    default_index=2
    ;;
  box)
    default_index=0
    ;;
  *)
    default_index=0
    ;;
  esac

  local previous_assume="$PROMPT_ASSUME_DEFAULTS"
  PROMPT_ASSUME_DEFAULTS=0

  local selection
  if ! selection=$(prompt_choice "$(msg theme_prompt_select)" "$default_index" "${options[@]}"); then
    PROMPT_ASSUME_DEFAULTS="$previous_assume"
    die "$(msg theme_selection_cancelled)"
  fi

  PROMPT_ASSUME_DEFAULTS="$previous_assume"

  case "$selection" in
  box | sage | archer)
    theme_set_with_feedback "$selection"
    ;;
  __reset__)
    theme_reset_with_feedback
    ;;
  *)
    die "$(msg theme_unknown_command "$selection")"
    ;;
  esac
}

is_help_token() {
  case "${1:-}" in
  -h | --help | help)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

shell_hook_usage() {
  case "$LANGUAGE" in
  zh)
    cat << 'HOOK_USAGE_ZH'
wt shell-hook 用法:
  wt shell-hook zsh
  wt shell-hook bash

将输出通过 eval/source 加载以安装包装函数，例如：
  eval "$(wt shell-hook zsh)"
HOOK_USAGE_ZH
    ;;
  *)
    cat << 'HOOK_USAGE_EN'
wt shell-hook usage:
  wt shell-hook zsh
  wt shell-hook bash

Pipe the output into eval/source to install the wrapper, e.g.
  eval "$(wt shell-hook zsh)"
HOOK_USAGE_EN
    ;;
  esac
}

uninstall_usage() {
  case "$LANGUAGE" in
  zh)
    cat << 'UNINSTALL_USAGE_ZH'
wt uninstall 用法:
  wt uninstall [--shell <shell>] [--prefix <dir>]

选项:
  --shell <shell>   指定要清理的 shell（zsh|bash|none；默认自动检测）
  --prefix <dir>    wt 安装目录（默认 $HOME/.local/bin）
  --help            查看帮助
UNINSTALL_USAGE_ZH
    ;;
  *)
    cat << 'UNINSTALL_USAGE_EN'
wt uninstall usage:
  wt uninstall [--shell <shell>] [--prefix <dir>]

Options:
  --shell <shell>   Shell to clean hooks for (zsh|bash|none; default: auto-detect)
  --prefix <dir>    Directory where wt is installed (default: $HOME/.local/bin)
  --help            Show this help
UNINSTALL_USAGE_EN
    ;;
  esac
}

reinstall_usage() {
  case "$LANGUAGE" in
  zh)
    cat << 'REINSTALL_USAGE_ZH'
wt reinstall 用法:
  wt reinstall [--shell <shell>] [--prefix <dir>]

说明:
  - 先运行 uninstall.sh，再运行 install.sh
  - 默认目标目录为 ~/.local/bin（可通过 WT_INSTALL_PREFIX 或 --prefix 覆盖）
  - 需在包含 install.sh 与 uninstall.sh 的仓库目录中运行
REINSTALL_USAGE_ZH
    ;;
  *)
    cat << 'REINSTALL_USAGE_EN'
wt reinstall usage:
  wt reinstall [--shell <shell>] [--prefix <dir>]

Notes:
  - Executes uninstall.sh followed by install.sh from this checkout
  - Targets ~/.local/bin by default (override via WT_INSTALL_PREFIX or --prefix)
  - Must be invoked from a checkout that contains install.sh and uninstall.sh
REINSTALL_USAGE_EN
    ;;
  esac
}

init_usage() {
  case "$LANGUAGE" in
  zh)
    cat << 'INIT_USAGE_ZH'
wt init 用法:
  wt init

请在目标仓库运行：
- 创建 ~/.worktree.sh/projects/<slug>/config.kv（如不存在）。
- 设置 repo.path 为仓库根目录（根据 git common dir 推导）。
INIT_USAGE_ZH
    ;;
  *)
    cat << 'INIT_USAGE_EN'
wt init usage:
  wt init

Run inside the target repository:
- Create ~/.worktree.sh/projects/<slug>/config.kv when missing.
- Set repo.path to the repository root (derived from git common dir).
INIT_USAGE_EN
    ;;
  esac
}

command_usage() {
  local command="${1:-}"

  case "$command" in
  help)
    msg help_usage
    ;;
  list)
    msg list_usage
    ;;
  main)
    msg main_usage
    ;;
  path)
    msg path_usage
    ;;
  add)
    msg add_usage
    ;;
  merge)
    msg merge_usage
    ;;
  sync)
    msg sync_usage
    ;;
  rm | remove)
    msg remove_usage
    ;;
  clean)
    msg clean_usage
    ;;
  detach)
    msg detach_usage
    ;;
  config)
    config_usage
    ;;
  lang)
    msg lang_usage
    ;;
  theme)
    msg theme_usage
    ;;
  shell-hook)
    shell_hook_usage
    ;;
  init)
    init_usage
    ;;
  uninstall)
    uninstall_usage
    ;;
  reinstall)
    reinstall_usage
    ;;
  *)
    return 1
    ;;
  esac
}

maybe_print_command_help() {
  local command="${1:-}"
  shift || true

  if [ $# -eq 0 ]; then
    return 1
  fi

  if ! is_help_token "$1"; then
    return 1
  fi

  command_usage "$command" || return 1
  return 0
}

cmd_config() {
  local scope="$CURRENT_SCOPE"
  if [ $# -eq 0 ]; then
    config_usage
    return
  fi

  if [ "$1" = "--stored" ]; then
    shift || die "$(msg config_get_requires_key)"
    set -- get --stored "$@"
  fi

  case "$1" in
  list | --list)
    if [ $# -ne 1 ]; then
      die "$(msg config_list_no_args)"
    fi
    if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -ne 1 ] && [ "$scope" != "project" ]; then
      die "$(msg command_requires_project)"
    fi
    init_settings
    config_print_effective
    ;;
  get | --get)
    shift || die "$(msg config_get_requires_key)"

    local stored_only=0
    while [ $# -gt 0 ]; do
      case "$1" in
      --stored)
        stored_only=1
        shift || true
        ;;
      --*)
        die "$(msg config_unknown_option "$1")"
        ;;
      *)
        break
        ;;
      esac
    done

    if [ $# -ne 1 ]; then
      die "$(msg config_get_requires_exactly_one)"
    fi

    local key="$1"
    if [ "$key" = "language" ]; then
      if [ "$stored_only" -eq 1 ]; then
        local stored
        if stored=$(config_file_get_value "$CONFIG_FILE_DEFAULT" "language" 2> /dev/null); then
          printf '%s\n' "$stored"
        else
          printf '%s\n' "$CONFIG_DEFAULT_LANGUAGE"
        fi
      else
        lang_print_current_value
      fi
      return
    fi
    if [ "$key" = "theme" ]; then
      if [ "$stored_only" -eq 1 ]; then
        local stored
        if stored=$(config_file_get_value "$CONFIG_FILE_DEFAULT" "theme" 2> /dev/null); then
          printf '%s\n' "$stored"
        else
          printf '%s\n' "$CONFIG_DEFAULT_THEME"
        fi
      else
        theme_print_current_value
      fi
      return
    fi
    local value
    if [ "$stored_only" -eq 1 ]; then
      if value=$(config_get "$key" 2> /dev/null); then
        printf '%s\n' "$value"
      else
        die "$(msg config_key_not_found "$key")"
      fi
    else
      if value=$(config_get_or_default "$key" 2> /dev/null); then
        printf '%s\n' "$value"
      else
        die "$(msg config_key_not_found "$key")"
      fi
    fi
    ;;
  set | --set)
    shift || die "$(msg config_set_requires)"
    if [ $# -ne 2 ]; then
      die "$(msg config_set_requires)"
    fi
    local key="$1"
    shift
    local value="$1"
    if [ "$key" = "language" ]; then
      lang_set_global_from_raw "$value"
      return
    fi
    if [ "$key" = "theme" ]; then
      theme_set_global_from_raw "$value"
      return
    fi
    if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -ne 1 ] && [ "$scope" != "project" ]; then
      die "$(msg command_requires_project)"
    fi
    config_set "$key" "$value"
    ;;
  unset | --unset)
    shift || die "$(msg config_unset_requires_key)"
    if [ $# -ne 1 ]; then
      die "$(msg config_unset_requires_exactly_one)"
    fi
    local key="$1"
    if [ "$key" = "language" ]; then
      lang_reset_global
      return
    fi
    if [ "$key" = "theme" ]; then
      theme_reset_global
      return
    fi
    if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -ne 1 ] && [ "$scope" != "project" ]; then
      die "$(msg command_requires_project)"
    fi
    config_unset "$key"
    ;;
  -h | --help | help)
    config_usage
    ;;
  --*)
    die "$(msg config_unknown_option "$1")"
    ;;
  *)
    local stored_only=0
    if [ $# -gt 0 ] && [ "$1" = "--stored" ]; then
      stored_only=1
      shift || true
    fi

    if [ $# -eq 1 ]; then
      local key="$1"
      if [ "$key" = "language" ]; then
        if [ "$stored_only" -eq 1 ]; then
          local stored
          if stored=$(config_file_get_value "$CONFIG_FILE_DEFAULT" "language" 2> /dev/null); then
            printf '%s\n' "$stored"
          else
            printf '%s\n' "$CONFIG_DEFAULT_LANGUAGE"
          fi
        else
          lang_print_current_value
        fi
        return
      fi
      if [ "$key" = "theme" ]; then
        if [ "$stored_only" -eq 1 ]; then
          local stored
          if stored=$(config_file_get_value "$CONFIG_FILE_DEFAULT" "theme" 2> /dev/null); then
            printf '%s\n' "$stored"
          else
            printf '%s\n' "$CONFIG_DEFAULT_THEME"
          fi
        else
          theme_print_current_value
        fi
        return
      fi
      local value
      if [ "$stored_only" -eq 1 ]; then
        if value=$(config_get "$key" 2> /dev/null); then
          printf '%s\n' "$value"
        else
          die "$(msg config_key_not_found "$key")"
        fi
      else
        if value=$(config_get_or_default "$key" 2> /dev/null); then
          printf '%s\n' "$value"
        else
          die "$(msg config_key_not_found "$key")"
        fi
      fi
    elif [ $# -eq 2 ]; then
      local key="$1"
      local value="$2"
      if [ "$key" = "language" ]; then
        lang_set_global_from_raw "$value"
        return
      fi
      if [ "$key" = "theme" ]; then
        theme_set_global_from_raw "$value"
        return
      fi
      if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -ne 1 ] && [ "$scope" != "project" ]; then
        die "$(msg command_requires_project)"
      fi
      config_set "$key" "$value"
    elif [ "$stored_only" -eq 1 ]; then
      die "$(msg config_get_requires_key)"
    else
      die "$(msg config_expect_key_or_value)"
    fi
    ;;
  esac
}

cmd_shell_hook() {
  if [ $# -eq 0 ]; then
    die "$(msg shell_hook_requires_shell)"
  fi

  case "$1" in
  -h | --help | help)
    shell_hook_usage
    return
    ;;
  esac

  local shell="$1"
  local wt_exec_path
  local wt_exec_path_escaped
  wt_exec_path="$SCRIPT_DIR/wt"
  wt_exec_path_escaped=$(printf '%s\n' "$wt_exec_path" | sed 's/[\\/&]/\\&/g')
  case "$shell" in
  zsh | bash)
    sed "s/__WT_BIN_PATH__/$wt_exec_path_escaped/g" << 'WT_HOOK'
# wt shell integration: auto-cd after wt add/path/main/remove/clean
wt() {
  local __wt_out __wt_status __wt_cmd __wt_should_cd=0 __wt_has_help=0 __wt_arg
  local __wt_bin="__WT_BIN_PATH__"

  if [ ! -x "$__wt_bin" ]; then
    local __wt_resolved=""
    if __wt_resolved="$(type -P wt 2>/dev/null)" && [ -x "$__wt_resolved" ]; then
      __wt_bin="$__wt_resolved"
    elif __wt_resolved="$(command -v wt 2>/dev/null)" && [ -n "$__wt_resolved" ] && [ -x "$__wt_resolved" ]; then
      __wt_bin="$__wt_resolved"
    else
      printf 'zsh: command not found: wt\n' >&2
      return 127
    fi
  fi

  __wt_out="$(WT_SHELL_WRAPPED=1 "$__wt_bin" "$@")"
  __wt_status=$?

  if [ $__wt_status -ne 0 ]; then
    if [ -n "$__wt_out" ]; then
      printf '%s\n' "$__wt_out"
    fi
    return $__wt_status
  fi

  if [ $# -eq 0 ]; then
    __wt_cmd="list"
  else
    __wt_cmd="$1"
  fi

  for __wt_arg in "$@"; do
    case "$__wt_arg" in
    help | -h | --help)
      __wt_has_help=1
      break
      ;;
    esac
  done

  case "$__wt_cmd" in
    add|main|path)
      __wt_should_cd=1
      ;;
    remove|rm|clean)
      __wt_should_cd=1
      ;;
    config|list|help|-h|--help|--version|version)
      __wt_should_cd=0
      ;;
    -*)
      __wt_should_cd=0
      ;;
    *)
      __wt_should_cd=1
      ;;
  esac

  if [ "$__wt_has_help" -eq 1 ]; then
    __wt_should_cd=0
  fi

  if [ $__wt_should_cd -eq 1 ] && [ -n "$__wt_out" ] && [ -d "$__wt_out" ]; then
    cd "$__wt_out" || return $?
    return 0
  fi

  if [ -n "$__wt_out" ]; then
    printf '%s\n' "$__wt_out"
  fi
}

# wt shell integration: end
WT_HOOK
    ;;
  *)
    die "$(msg shell_hook_unsupported_shell "$shell")"
    ;;
  esac
}

cmd_lang() {
  if [ $# -eq 0 ]; then
    prompt_init_ui
    if [ "$PROMPT_HAS_TTY" -eq 1 ]; then
      lang_prompt_interactive
    else
      lang_print_current_value
    fi
    return
  fi

  case "$1" in
  help | --help | -h)
    msg lang_usage
    ;;
  get | --get)
    lang_print_current_value
    ;;
  set | --set)
    shift || die "$(msg lang_set_requires)"
    if [ $# -ne 1 ]; then
      die "$(msg lang_set_requires)"
    fi
    lang_set_with_feedback "$1"
    ;;
  reset | --reset)
    lang_reset_with_feedback
    ;;
  en | zh)
    lang_set_with_feedback "$1"
    ;;
  *)
    die "$(msg lang_unknown_command "$1")"
    ;;
  esac
}

cmd_theme() {
  if [ $# -eq 0 ]; then
    prompt_init_ui
    if [ "$PROMPT_HAS_TTY" -eq 1 ]; then
      theme_prompt_interactive
    else
      theme_print_current_value
    fi
    return
  fi

  case "$1" in
  help | --help | -h)
    msg theme_usage
    ;;
  get | --get)
    theme_print_current_value
    ;;
  set | --set)
    shift || die "$(msg theme_set_requires)"
    if [ $# -ne 1 ]; then
      die "$(msg theme_set_requires)"
    fi
    theme_set_with_feedback "$1"
    ;;
  reset | --reset)
    theme_reset_with_feedback
    ;;
  box | sage | archer)
    theme_set_with_feedback "$1"
    ;;
  *)
    die "$(msg theme_unknown_command "$1")"
    ;;
  esac
}

uninstall_remove_shell_hook() {
  local shell_type="$1"
  local hook_file=""
  local hook_marker="# wt shell integration: auto-cd after wt add/path/main/remove/clean"
  local marker_end="# wt shell integration: end"

  case "$shell_type" in
  zsh)
    hook_file="$HOME/.zshrc"
    ;;
  bash)
    hook_file="$HOME/.bashrc"
    ;;
  *)
    info "$(msg uninstall_unknown_shell_type "$shell_type")"
    return 0
    ;;
  esac

  if [ ! -f "$hook_file" ]; then
    info "$(msg uninstall_shell_config_missing "$hook_file")"
    return 0
  fi

  if ! grep -Fq "$hook_marker" "$hook_file"; then
    info "$(msg uninstall_shell_hook_missing "$hook_file")"
    return 0
  fi

  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  cp "$hook_file" "${hook_file}.backup.${timestamp}"
  info "$(msg uninstall_backup_created "$hook_file" "$timestamp")"

  local tmpfile
  tmpfile=$(mktemp) || die "$(msg temp_file_failed)"

  awk -v start="$hook_marker" -v finish="$marker_end" '
    BEGIN { mode=0 }
    {
      if (mode==0) {
        if ($0 == start) { mode=1; next }
        print
        next
      }

      if (mode==1) {
        if ($0 == finish) { mode=2; next }
        next
      }

      if (mode==2) {
        if ($0 ~ /^[[:space:]]*$/) { mode=0; next }
        mode=0
        print
        next
      }
    }
  ' "$hook_file" > "$tmpfile"

  mv "$tmpfile" "$hook_file"
  info "$(msg uninstall_shell_hook_removed "$hook_file")"
}

uninstall_backup_config() {
  local config_path="$CONFIG_FILE"
  local default_dir="$CONFIG_DIR_DEFAULT"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)

  if [ "$config_path" = "$CONFIG_FILE_DEFAULT" ] && [ -d "$default_dir" ]; then
    local backup_path="${default_dir}.backup.${timestamp}"
    local candidate="$backup_path"
    local idx=1
    while [ -e "$candidate" ]; do
      candidate="${backup_path}.${idx}"
      idx=$((idx + 1))
    done
    mv "$default_dir" "$candidate"
    info "$(msg uninstall_config_backup_created "$default_dir" "$candidate")"
    return
  fi

  if [ -f "$config_path" ]; then
    local backup_path="${config_path}.backup.${timestamp}"
    local candidate="$backup_path"
    local idx=1
    while [ -e "$candidate" ]; do
      candidate="${backup_path}.${idx}"
      idx=$((idx + 1))
    done
    mv "$config_path" "$candidate"
    info "$(msg uninstall_config_backup_created "$config_path" "$candidate")"
  fi
}

cmd_uninstall() {
  local prefix="${WT_INSTALL_PREFIX:-$HOME/.local/bin}"
  local shell_type=""

  while [ $# -gt 0 ]; do
    case "$1" in
    --shell)
      shift || die "$(msg uninstall_requires_shell_value)"
      shell_type="$1"
      ;;
    --prefix)
      shift || die "$(msg uninstall_requires_prefix_value)"
      prefix="$1"
      ;;
    -h | --help | help)
      uninstall_usage
      return
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "$(msg uninstall_unknown_option "$1")"
      ;;
    *)
      die "$(msg uninstall_no_positional)"
      ;;
    esac
    shift || true
  done

  if [ $# -gt 0 ]; then
    die "$(msg uninstall_no_positional)"
  fi

  if [ -z "$shell_type" ]; then
    shell_type=$(detect_shell_type)
    info "$(msg uninstall_auto_detected_shell "$shell_type")"
  fi

  case "$shell_type" in
  zsh | bash | none) ;;
  *)
    die "$(msg uninstall_invalid_shell "$shell_type")"
    ;;
  esac

  local wt_bin="$prefix/wt"
  if [ -f "$wt_bin" ]; then
    rm -f "$wt_bin"
    info "$(msg uninstall_removed_binary "$wt_bin")"
  else
    info "$(msg uninstall_binary_missing "$wt_bin")"
  fi

  local messages_file="$prefix/messages.sh"
  if [ -f "$messages_file" ]; then
    rm -f "$messages_file"
    info "$(msg uninstall_removed_messages "$messages_file")"
  fi

  if [ "$shell_type" != "none" ]; then
    uninstall_remove_shell_hook "$shell_type"
  else
    info "$(msg uninstall_skip_shell_cleanup)"
  fi

  uninstall_backup_config

  info "$(msg uninstall_complete)"
  info "$(msg uninstall_worktrees_preserved)"
}

cmd_reinstall() {
  local prefix="${WT_INSTALL_PREFIX:-$HOME/.local/bin}"
  local shell_type=""

  while [ $# -gt 0 ]; do
    case "$1" in
    --shell)
      shift || die "$(msg reinstall_requires_shell_value)"
      shell_type="$1"
      ;;
    --prefix)
      shift || die "$(msg reinstall_requires_prefix_value)"
      prefix="$1"
      ;;
    -h | --help | help)
      reinstall_usage
      return
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "$(msg reinstall_unknown_option "$1")"
      ;;
    *)
      die "$(msg reinstall_no_positional)"
      ;;
    esac
    shift || true
  done

  if [ $# -gt 0 ]; then
    die "$(msg reinstall_no_positional)"
  fi

  local uninstall_script=""
  local install_script=""
  local cleanup_dir=""

  cleanup_reinstall_tmp() {
    if [ -n "$cleanup_dir" ] && [ -d "$cleanup_dir" ]; then
      rm -rf "$cleanup_dir"
    fi
    cleanup_dir=""
  }

  local remote_base="${WT_REINSTALL_REMOTE_BASE:-https://raw.githubusercontent.com/notdp/worktree.sh/main}"
  command -v curl > /dev/null 2>&1 || die "$(msg reinstall_curl_required)"

  cleanup_dir=$(mktemp -d)
  if [ -z "$cleanup_dir" ] || [ ! -d "$cleanup_dir" ]; then
    die "$(msg reinstall_fetch_failed "$remote_base")"
  fi

  uninstall_script="$cleanup_dir/uninstall.sh"
  install_script="$cleanup_dir/install.sh"
  local uninstall_url="$remote_base/uninstall.sh"
  local install_url="$remote_base/install.sh"

  info "$(msg reinstall_fetch_remote_uninstall "$uninstall_url")"
  if ! curl -fsSL "$uninstall_url" -o "$uninstall_script"; then
    cleanup_reinstall_tmp
    die "$(msg reinstall_fetch_failed "$uninstall_url")"
  fi
  info "$(msg reinstall_fetch_remote_install "$install_url")"
  if ! curl -fsSL "$install_url" -o "$install_script"; then
    cleanup_reinstall_tmp
    die "$(msg reinstall_fetch_failed "$install_url")"
  fi
  chmod +x "$uninstall_script" "$install_script" 2> /dev/null || true

  local -a uninstall_cmd=("$uninstall_script")
  local -a install_cmd=("$install_script")

  if [ -n "$shell_type" ]; then
    uninstall_cmd+=('--shell' "$shell_type")
    install_cmd+=('--shell' "$shell_type")
  fi

  uninstall_cmd+=('--prefix' "$prefix")
  install_cmd+=('--prefix' "$prefix")

  local uninstall_display=""
  local install_display=""

  printf -v uninstall_display '%q ' "${uninstall_cmd[@]}"
  uninstall_display=${uninstall_display%% }
  printf -v install_display '%q ' "${install_cmd[@]}"
  install_display=${install_display%% }

  info "$(msg reinstall_running "$uninstall_display")"
  if ! "${uninstall_cmd[@]}"; then
    cleanup_reinstall_tmp
    die "$(msg reinstall_uninstall_failed "$uninstall_script")"
  fi

  info "$(msg reinstall_running "$install_display")"
  if ! "${install_cmd[@]}"; then
    cleanup_reinstall_tmp
    die "$(msg reinstall_install_failed "$install_script")"
  fi

  cleanup_reinstall_tmp

  info "$(msg reinstall_complete)"
}

init_option_append_unique() {
  local array_name="$1"
  local value="$2"
  local label="$3"
  local hint="$4"

  local -a option_ref=()
  if eval "test -n \"\${${array_name}+x}\""; then
    eval "option_ref=(\"\${${array_name}[@]}\")"
  fi
  local existing
  if [ ${#option_ref[@]} -gt 0 ]; then
    for existing in "${option_ref[@]}"; do
      local current="${existing#*|}"
      current="${current%%|*}"
      if [ "$current" = "$value" ]; then
        return 0
      fi
    done
  fi

  local entry
  printf -v entry '%s|%s|%s' "$label" "$value" "$hint"
  if ! eval "test -n \"\${${array_name}+x}\""; then
    eval "${array_name}=()"
  fi
  eval "${array_name}+=(\"\$entry\")"
}

init_option_find_index() {
  local array_name="$1"
  local target="$2"

  local -a option_ref=()
  if eval "test -n \"\${${array_name}+x}\""; then
    eval "option_ref=(\"\${${array_name}[@]}\")"
  fi
  local idx=0
  local entry
  if [ ${#option_ref[@]} -gt 0 ]; then
    for entry in "${option_ref[@]}"; do
      local current="${entry#*|}"
      current="${current%%|*}"
      if [ "$current" = "$target" ]; then
        printf '%d\n' "$idx"
        return 0
      fi
      idx=$((idx + 1))
    done
  fi

  printf '%d\n' -1
}

init_option_extract_value() {
  local entry="$1"
  local remainder="${entry#*|}"
  printf '%s\n' "${remainder%%|*}"
}

init_option_focus_default() {
  local array_name="$1"
  local target_index="$2"

  local -a option_ref=()
  if eval "test -n \"\${${array_name}+x}\""; then
    eval "option_ref=(\"\${${array_name}[@]}\")"
  fi
  local count=${#option_ref[@]}
  if [ "$target_index" -lt 0 ] || [ "$target_index" -ge "$count" ]; then
    printf '%d\n' 0
    return 0
  fi

  if [ "$target_index" -eq 0 ]; then
    printf '%d\n' 0
    return 0
  fi

  local default_entry="${option_ref[$target_index]}"
  local -a reordered=("$default_entry")
  local idx
  if [ ${#option_ref[@]} -gt 0 ]; then
    for idx in "${!option_ref[@]}"; do
      if [ "$idx" -eq "$target_index" ]; then
        continue
      fi
      reordered+=("${option_ref[$idx]}")
    done
  fi

  eval "${array_name}=(\"\${reordered[@]}\")"
  printf '%d\n' 0
}

cmd_init() {
  local branch_option="" assume_yes=0
  while [ $# -gt 0 ]; do
    case "$1" in
    --branch | branch)
      shift || die "$(msg branch_requires_value)"
      branch_option="$1"
      ;;
    -y | --yes)
      assume_yes=1
      ;;
    --help | help)
      init_usage
      return
      ;;
    -*)
      die "$(msg init_unknown_option "$1")"
      ;;
    *)
      die "$(msg init_no_positional)"
      ;;
    esac
    shift || true
  done

  local git_common
  git_common=$(git rev-parse --git-common-dir --path-format=absolute 2> /dev/null) || die "$(msg init_run_inside_git)"

  local repo_root
  repo_root=$(dirname "$git_common")
  local repo_root_abs
  if ! repo_root_abs=$(cd "$repo_root" 2> /dev/null && pwd -P); then
    repo_root_abs="$repo_root"
  fi

  local home_dir_abs
  if ! home_dir_abs=$(cd "$HOME" 2> /dev/null && pwd -P); then
    home_dir_abs="$HOME"
  fi

  if [ "$repo_root_abs" = "$home_dir_abs" ]; then
    die "$(msg init_forbid_home "$repo_root_abs")"
  fi

  local slug
  slug=$(project_slug_for_path "$repo_root_abs") || die "$(msg init_slug_failed)"
  local target_file
  target_file=$(project_config_file_for_slug "$slug")

  config_ensure_parent_dir "$target_file" || die "$(msg config_update_failed)"

  local template_file="$SCRIPT_DIR/../config-example.kv"
  local created=0
  if [ ! -f "$target_file" ]; then
    if [ -f "$template_file" ]; then
      cp "$template_file" "$target_file" || die "$(msg config_update_failed)"
    else
      : > "$target_file" || die "$(msg config_update_failed)"
    fi
    chmod 600 "$target_file" 2> /dev/null || true
    created=1
  else
    local existing_path
    existing_path=$(config_file_get_value "$target_file" "repo.path" 2> /dev/null || true)
    if [ -n "$existing_path" ] && [ "$existing_path" != "$repo_root_abs" ]; then
      die "$(msg init_slug_mismatch "$slug" "$existing_path" "$repo_root_abs")"
    fi
  fi

  local value
  local bool_val
  local copy_env_enabled_default="$CONFIG_DEFAULT_COPY_ENV_ENABLED"
  local -a copy_env_files_default=("${CONFIG_DEFAULT_COPY_ENV_FILES[@]}")
  local install_enabled_default="$CONFIG_DEFAULT_INSTALL_DEPS_ENABLED"
  local install_command_default="$CONFIG_DEFAULT_INSTALL_DEPS_COMMAND"
  local serve_enabled_default="$CONFIG_DEFAULT_SERVE_DEV_ENABLED"
  local serve_command_default="$CONFIG_DEFAULT_SERVE_DEV_COMMAND"
  local serve_logging_path_default="$CONFIG_DEFAULT_SERVE_DEV_LOGGING_PATH"
  local branch_prefix_default="$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX"

  if value=$(config_file_get_value "$target_file" "add.copy-env.enabled" 2> /dev/null || true); then
    if bool_val=$(parse_bool "$value" 2> /dev/null); then
      copy_env_enabled_default="$bool_val"
    fi
  fi

  if value=$(config_file_get_value "$target_file" "add.copy-env.files" 2> /dev/null || true); then
    if [ -n "$value" ] && [[ "$value" =~ ^\[.*\]$ ]]; then
      local trimmed
      trimmed="${value#[}"
      trimmed="${trimmed%]}"
      local -a parsed_files=()
      if [ -n "$trimmed" ]; then
        IFS=',' read -r -a parsed_files <<< "$trimmed"
      fi
      copy_env_files_default=()
      if [ ${#parsed_files[@]} -gt 0 ]; then
        local item
        for item in "${parsed_files[@]}"; do
          item="${item#"${item%%[![:space:]]*}"}"
          item="${item%"${item##*[![:space:]]}"}"
          item="${item#\"}"
          item="${item%\"}"
          [ -n "$item" ] && copy_env_files_default+=("$item")
        done
      fi
    fi
  fi

  if value=$(config_file_get_value "$target_file" "add.install-deps.enabled" 2> /dev/null || true); then
    if bool_val=$(parse_bool "$value" 2> /dev/null); then
      install_enabled_default="$bool_val"
    fi
  fi

  if value=$(config_file_get_value "$target_file" "add.install-deps.command" 2> /dev/null || true); then
    install_command_default="$value"
  fi
  install_command_default=$(prompt_trim_spaces "$install_command_default")

  if value=$(config_file_get_value "$target_file" "add.serve-dev.enabled" 2> /dev/null || true); then
    if bool_val=$(parse_bool "$value" 2> /dev/null); then
      serve_enabled_default="$bool_val"
    fi
  fi

  if value=$(config_file_get_value "$target_file" "add.serve-dev.command" 2> /dev/null || true); then
    serve_command_default="$value"
  fi
  serve_command_default=$(prompt_trim_spaces "$serve_command_default")

  if value=$(config_file_get_value "$target_file" "add.serve-dev.logging-path" 2> /dev/null || true); then
    serve_logging_path_default="$value"
  fi
  serve_logging_path_default=$(prompt_trim_spaces "$serve_logging_path_default")

  if value=$(config_file_get_value "$target_file" "add.branch-prefix" 2> /dev/null || true); then
    branch_prefix_default="$value"
  fi
  branch_prefix_default=$(prompt_trim_spaces "$branch_prefix_default")

  local previous_prompt_assume="$PROMPT_ASSUME_DEFAULTS"
  PROMPT_ASSUME_DEFAULTS="$assume_yes"

  local repo_input
  if ! repo_input=$(prompt_input_text "$(msg init_prompt_repo_path)" "$repo_root_abs" 0); then
    PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
    die "$(msg aborted)"
  fi
  repo_input=$(prompt_trim_spaces "$repo_input")
  if [ -z "$repo_input" ]; then
    repo_input="$repo_root_abs"
  fi
  local repo_path_selected
  if repo_path_selected=$(cd "$repo_input" 2> /dev/null && pwd -P); then
    :
  else
    repo_path_selected="$repo_input"
  fi

  local copy_env_choice
  if ! copy_env_choice=$(prompt_confirm "$(msg init_prompt_copy_env)" "$copy_env_enabled_default"); then
    PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
    die "$(msg aborted)"
  fi
  if [ "$copy_env_choice" -ne 0 ]; then
    copy_env_choice=1
  else
    copy_env_choice=0
  fi

  local -a copy_env_files=("${copy_env_files_default[@]}")
  local copy_env_files_str=""
  if [ ${#copy_env_files_default[@]} -gt 0 ]; then
    copy_env_files_str=$(prompt_join_by_space "${copy_env_files_default[@]}")
  fi

  if [ "$copy_env_choice" -eq 1 ]; then
    local env_input
    if ! env_input=$(prompt_input_text "$(msg init_prompt_copy_env_files)" "$copy_env_files_str" 1); then
      PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
      die "$(msg aborted)"
    fi
    env_input=$(prompt_trim_spaces "$env_input")
    if [ -z "$env_input" ]; then
      copy_env_files=("${copy_env_files_default[@]}")
    else
      case "$env_input" in
      none | None | NONE | 无)
        copy_env_files=()
        ;;
      *)
        local normalized
        normalized="${env_input//,/ }"
        copy_env_files=()
        local token
        for token in $normalized; do
          token=$(prompt_trim_spaces "$token")
          if [ -n "$token" ]; then
            copy_env_files+=("$token")
          fi
        done
        ;;
      esac
    fi
  else
    local files_summary_display
    if [ -n "$copy_env_files_str" ]; then
      files_summary_display=$(prompt_style_gray "$copy_env_files_str")
    else
      files_summary_display=$(prompt_style_gray "$(msg prompt_empty_display)")
    fi
    prompt_success_line "$(msg init_prompt_copy_env_files)" "$files_summary_display"
  fi

  # shellcheck disable=SC2034
  local repo_has_package_json=0
  local repo_has_package_lock=0
  local repo_has_pnpm=0
  local repo_has_yarn=0
  local repo_has_bun=0
  local repo_has_poetry=0
  local repo_has_pipenv=0
  local repo_has_requirements=0
  local repo_has_uv=0
  local repo_has_manage=0
  local repo_has_app=0
  local repo_python_tool=""
  local repo_python_framework=""

  if [ -f "$repo_path_selected/package.json" ]; then
    repo_has_package_json=1
    if [ -f "$repo_path_selected/package-lock.json" ] || [ -f "$repo_path_selected/npm-shrinkwrap.json" ]; then
      repo_has_package_lock=1
    fi
  fi

  if [ -f "$repo_path_selected/pnpm-lock.yaml" ] || [ -f "$repo_path_selected/pnpm-workspace.yaml" ]; then
    repo_has_pnpm=1
  fi

  if [ -f "$repo_path_selected/yarn.lock" ]; then
    repo_has_yarn=1
  fi

  if [ -f "$repo_path_selected/bun.lockb" ]; then
    repo_has_bun=1
  fi

  if [ -f "$repo_path_selected/Pipfile" ]; then
    # shellcheck disable=SC2034
    repo_has_pipenv=1
  fi

  if [ -f "$repo_path_selected/requirements.txt" ]; then
    # shellcheck disable=SC2034
    repo_has_requirements=1
  fi

  if [ -f "$repo_path_selected/poetry.lock" ]; then
    # shellcheck disable=SC2034
    repo_has_poetry=1
  fi

  if [ -f "$repo_path_selected/pyproject.toml" ]; then
    if grep -qi '^[[:space:]]*\[tool\.poetry\]' "$repo_path_selected/pyproject.toml" 2> /dev/null; then
      # shellcheck disable=SC2034
      repo_has_poetry=1
    fi
    if grep -qi '^[[:space:]]*\[tool\.uv\]' "$repo_path_selected/pyproject.toml" 2> /dev/null; then
      # shellcheck disable=SC2034
      repo_has_uv=1
    fi
  fi

  if [ -f "$repo_path_selected/uv.lock" ]; then
    # shellcheck disable=SC2034
    repo_has_uv=1
  fi

  if [ -f "$repo_path_selected/manage.py" ]; then
    # shellcheck disable=SC2034
    repo_has_manage=1
  fi

  if [ -f "$repo_path_selected/app.py" ]; then
    # shellcheck disable=SC2034
    repo_has_app=1
  fi

  # 使用新的 Python 检测函数
  repo_python_tool=""
  if repo_python_tool=$(detect_python_tool "$repo_path_selected" 2> /dev/null); then
    :
  else
    repo_python_tool=""
  fi

  repo_python_framework=""
  if repo_python_framework=$(detect_python_framework "$repo_path_selected" 2> /dev/null); then
    :
  else
    repo_python_framework=""
  fi

  local package_has_dev=0
  if [ "$repo_has_package_json" -eq 1 ]; then
    if has_package_json_script "$repo_path_selected" dev; then
      package_has_dev=1
    fi
  fi

  local install_command_inferred=""
  if install_command_inferred=$(infer_install_command "$repo_path_selected" 2> /dev/null); then
    install_command_inferred=$(prompt_trim_spaces "$install_command_inferred")
  else
    install_command_inferred=""
  fi

  local serve_command_inferred=""
  if serve_command_inferred=$(infer_serve_command "$repo_path_selected" 2> /dev/null); then
    serve_command_inferred=$(prompt_trim_spaces "$serve_command_inferred")
  else
    serve_command_inferred=""
  fi

  local -a install_options=()
  if [ "$repo_has_package_lock" -eq 1 ]; then
    init_option_append_unique install_options 'npm ci' 'npm ci' "$(msg init_install_option_npm_ci_hint)"
  fi
  if [ "$repo_has_package_json" -eq 1 ]; then
    init_option_append_unique install_options 'npm install' 'npm install' "$(msg init_install_option_npm_install_hint)"
  fi
  if [ "$repo_has_pnpm" -eq 1 ]; then
    init_option_append_unique install_options 'pnpm install' 'pnpm install' "$(msg init_install_option_pnpm_install_hint)"
  fi
  if [ "$repo_has_yarn" -eq 1 ]; then
    init_option_append_unique install_options 'yarn install' 'yarn install' "$(msg init_install_option_yarn_install_hint)"
  fi
  if [ "$repo_has_bun" -eq 1 ]; then
    init_option_append_unique install_options 'bun install' 'bun install' "$(msg init_install_option_bun_install_hint)"
  fi
  # Python 项目的安装命令选项
  if [ -n "$repo_python_tool" ]; then
    local has_venv=0
    if detect_python_venv "$repo_path_selected" > /dev/null; then
      has_venv=1
    fi

    local install_cmd
    if install_cmd=$(generate_python_install_cmd "$repo_path_selected" "$repo_python_tool" "$has_venv"); then
      # 生成友好的提示文本
      local install_hint=""
      case "$repo_python_tool" in
      uv)
        install_hint="$(msg init_install_option_uv_sync_hint)"
        ;;
      poetry)
        install_hint="$(msg init_install_option_poetry_install_hint)"
        ;;
      pipenv)
        install_hint="$(msg init_install_option_pipenv_install_hint)"
        ;;
      pdm)
        install_hint="$(msg init_install_option_pdm_install_hint)"
        ;;
      rye)
        install_hint="$(msg init_install_option_rye_install_hint)"
        ;;
      hatch)
        install_hint="$(msg init_install_option_hatch_install_hint)"
        ;;
      conda)
        install_hint="$(msg init_install_option_conda_hint)"
        ;;
      pip)
        if [ "$has_venv" -eq 0 ]; then
          install_hint="$(msg init_install_option_pip_create_venv_hint)"
        else
          install_hint="$(msg init_install_option_pip_requirements_hint)"
        fi
        ;;
      esac

      init_option_append_unique install_options "$install_cmd" "$install_cmd" "$install_hint"
    fi
  fi

  if [ -n "$install_command_inferred" ]; then
    init_option_append_unique install_options "$install_command_inferred" "$install_command_inferred" "$(msg init_install_option_detected_hint)"
  fi

  if [ "$created" -eq 0 ] && [ -n "$install_command_default" ]; then
    init_option_append_unique install_options "$install_command_default" "$install_command_default" "$(msg init_install_option_existing_hint)"
  fi

  init_option_append_unique install_options '__skip__' "$(msg init_install_option_skip_label)" "$(msg init_install_option_skip_hint)"
  init_option_append_unique install_options '__custom__' "$(msg init_install_option_custom_label)" "$(msg init_install_option_custom_hint)"

  local default_install_index
  if [ "$install_enabled_default" -eq 0 ]; then
    default_install_index=$(init_option_find_index install_options '__skip__')
  else
    local desired_install_command=""
    if [ "$created" -eq 0 ] && [ -n "$install_command_default" ]; then
      desired_install_command="$install_command_default"
    elif [ -n "$install_command_inferred" ]; then
      desired_install_command="$install_command_inferred"
    elif [ -n "$install_command_default" ]; then
      desired_install_command="$install_command_default"
    elif [ ${#install_options[@]} -gt 0 ]; then
      desired_install_command=$(init_option_extract_value "${install_options[0]}")
    fi

    default_install_index=-1
    if [ -n "$desired_install_command" ]; then
      default_install_index=$(init_option_find_index install_options "$desired_install_command")
    fi

    if [ "$default_install_index" -lt 0 ]; then
      default_install_index=$(init_option_find_index install_options '__skip__')
    fi
  fi

  if [ "$default_install_index" -lt 0 ]; then
    default_install_index=0
  fi

  default_install_index=$(init_option_focus_default install_options "$default_install_index")

  local install_selection
  if ! install_selection=$(prompt_choice "$(msg init_prompt_install_command)" "$default_install_index" "${install_options[@]}"); then
    PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
    die "$(msg aborted)"
  fi

  local install_enabled
  local install_command
  if [ "$install_selection" = "__skip__" ]; then
    install_enabled=0
    install_command=""
  elif [ "$install_selection" = "__custom__" ]; then
    install_enabled=1
    if ! install_command=$(prompt_input_text "$(msg init_prompt_install_custom)" "$install_command_default" 1); then
      PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
      die "$(msg aborted)"
    fi
    install_command=$(prompt_trim_spaces "$install_command")
  else
    install_enabled=1
    install_command="$install_selection"
  fi

  local -a serve_options=()
  if [ "$repo_has_pnpm" -eq 1 ] && [ "$package_has_dev" -eq 1 ]; then
    init_option_append_unique serve_options 'pnpm dev' 'pnpm dev' "$(msg init_serve_option_pnpm_dev_hint)"
  fi
  if [ "$repo_has_yarn" -eq 1 ] && [ "$package_has_dev" -eq 1 ]; then
    init_option_append_unique serve_options 'yarn dev' 'yarn dev' "$(msg init_serve_option_yarn_dev_hint)"
  fi
  if [ "$repo_has_bun" -eq 1 ] && [ "$package_has_dev" -eq 1 ]; then
    init_option_append_unique serve_options 'bun dev' 'bun dev' "$(msg init_serve_option_bun_dev_hint)"
  fi
  if [ "$repo_has_package_json" -eq 1 ] && [ "$package_has_dev" -eq 1 ]; then
    init_option_append_unique serve_options 'npm run dev' 'npm run dev' "$(msg init_serve_option_npm_run_dev_hint)"
  fi
  # Python 项目的服务命令选项
  if [ -n "$repo_python_tool" ] && [ -n "$repo_python_framework" ]; then
    local venv_path=""
    if detect_python_venv "$repo_path_selected" > /dev/null; then
      venv_path="$repo_path_selected/$(detect_python_venv "$repo_path_selected")"
    fi

    local serve_cmd
    serve_cmd=$(generate_python_serve_cmd "$repo_path_selected" "$repo_python_tool" "$repo_python_framework" "$venv_path")

    # 生成友好的提示文本
    local hint_text=""
    case "$repo_python_tool" in
    uv)
      hint_text="$(msg init_serve_option_uv_run_hint)"
      ;;
    poetry)
      hint_text="$(msg init_serve_option_poetry_run_hint)"
      ;;
    pipenv)
      hint_text="$(msg init_serve_option_pipenv_run_hint)"
      ;;
    pdm)
      hint_text="$(msg init_serve_option_pdm_run_hint)"
      ;;
    rye)
      hint_text="$(msg init_serve_option_rye_run_hint)"
      ;;
    hatch)
      hint_text="$(msg init_serve_option_hatch_run_hint)"
      ;;
    conda)
      hint_text="$(msg init_serve_option_conda_hint)"
      ;;
    pip)
      if [ -n "$venv_path" ]; then
        hint_text="$(msg init_serve_option_pip_venv_hint)"
      else
        hint_text="$(msg init_serve_option_python_app_hint)"
      fi
      ;;
    esac

    init_option_append_unique serve_options "$serve_cmd" "$serve_cmd" "$hint_text"
  fi

  if [ -z "$repo_python_tool" ]; then
    local fallback_cmd=""
    local fallback_hint=""

    if [ "${repo_has_manage:-0}" -eq 1 ] && [ -f "$repo_path_selected/manage.py" ]; then
      fallback_cmd='python manage.py runserver'
      fallback_hint="$(msg init_serve_option_manage_runserver_hint)"
    else
      local fallback_target=""
      if [ -f "$repo_path_selected/main.py" ]; then
        fallback_target='main.py'
      elif [ -f "$repo_path_selected/app.py" ]; then
        fallback_target='app.py'
      elif [ -f "$repo_path_selected/app/main.py" ]; then
        fallback_target='app/main.py'
      elif [ -f "$repo_path_selected/src/main.py" ]; then
        fallback_target='src/main.py'
      fi

      if [ -n "$fallback_target" ]; then
        fallback_cmd="python $fallback_target"
        fallback_hint="$(msg init_serve_option_python_app_hint)"
      fi
    fi

    if [ -n "$fallback_cmd" ]; then
      init_option_append_unique serve_options "$fallback_cmd" "$fallback_cmd" "$fallback_hint"
    fi
  fi

  if [ -n "$serve_command_inferred" ]; then
    init_option_append_unique serve_options "$serve_command_inferred" "$serve_command_inferred" "$(msg init_serve_option_detected_hint)"
  fi

  if [ "$created" -eq 0 ] && [ -n "$serve_command_default" ]; then
    init_option_append_unique serve_options "$serve_command_default" "$serve_command_default" "$(msg init_serve_option_existing_hint)"
  fi

  init_option_append_unique serve_options '__skip__' "$(msg init_serve_option_skip_label)" "$(msg init_serve_option_skip_hint)"
  init_option_append_unique serve_options '__custom__' "$(msg init_serve_option_custom_label)" "$(msg init_serve_option_custom_hint)"

  local default_serve_index
  if [ "$serve_enabled_default" -eq 0 ]; then
    default_serve_index=$(init_option_find_index serve_options '__skip__')
  else
    local desired_serve_command=""
    if [ "$created" -eq 0 ] && [ -n "$serve_command_default" ]; then
      desired_serve_command="$serve_command_default"
    elif [ -n "$serve_command_inferred" ]; then
      desired_serve_command="$serve_command_inferred"
    elif [ -n "$serve_command_default" ]; then
      desired_serve_command="$serve_command_default"
    elif [ ${#serve_options[@]} -gt 0 ]; then
      desired_serve_command=$(init_option_extract_value "${serve_options[0]}")
    fi

    default_serve_index=-1
    if [ -n "$desired_serve_command" ]; then
      default_serve_index=$(init_option_find_index serve_options "$desired_serve_command")
    fi

    if [ "$default_serve_index" -lt 0 ]; then
      default_serve_index=$(init_option_find_index serve_options '__skip__')
    fi
  fi

  if [ "$default_serve_index" -lt 0 ]; then
    default_serve_index=0
  fi

  default_serve_index=$(init_option_focus_default serve_options "$default_serve_index")

  local serve_selection
  if ! serve_selection=$(prompt_choice "$(msg init_prompt_serve_command)" "$default_serve_index" "${serve_options[@]}"); then
    PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
    die "$(msg aborted)"
  fi

  local serve_enabled
  local serve_command
  if [ "$serve_selection" = "__skip__" ]; then
    serve_enabled=0
    serve_command=""
  elif [ "$serve_selection" = "__custom__" ]; then
    serve_enabled=1
    if ! serve_command=$(prompt_input_text "$(msg init_prompt_serve_custom)" "$serve_command_default" 1); then
      PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
      die "$(msg aborted)"
    fi
    serve_command=$(prompt_trim_spaces "$serve_command")
  else
    serve_enabled=1
    serve_command="$serve_selection"
  fi

  local serve_logging_path="$serve_logging_path_default"
  if [ "$serve_enabled" -ne 0 ]; then
    if ! serve_logging_path=$(prompt_input_text "$(msg init_prompt_serve_logging_path)" "$serve_logging_path_default" 1); then
      PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
      die "$(msg aborted)"
    fi
    serve_logging_path=$(prompt_trim_spaces "$serve_logging_path")
    case "$serve_logging_path" in
    none | None | NONE | 无)
      serve_logging_path=""
      ;;
    esac
  else
    local logging_display
    if [ -n "$serve_logging_path_default" ]; then
      logging_display=$(prompt_style_gray "$serve_logging_path_default")
    else
      logging_display=$(prompt_style_gray "$(msg prompt_empty_display)")
    fi
    prompt_success_line "$(msg init_prompt_serve_logging_path)" "$logging_display"
  fi

  local -a branch_options=()
  if [ -n "$branch_prefix_default" ]; then
    init_option_append_unique branch_options "$branch_prefix_default" "$branch_prefix_default" "$(msg init_branch_option_current_hint)"
  fi
  init_option_append_unique branch_options "$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX" "$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX" "$(msg init_branch_option_default_hint)"
  local branch_fallback
  for branch_fallback in "${CONFIG_BRANCH_PREFIX_FALLBACKS[@]}"; do
    init_option_append_unique branch_options "$branch_fallback" "$branch_fallback" "$(msg init_branch_option_alternative_hint)"
  done

  init_option_append_unique branch_options '__skip__' "$(msg init_branch_option_skip_label)" "$(msg init_branch_option_skip_hint)"
  init_option_append_unique branch_options '__custom__' "$(msg init_branch_option_custom_label)" "$(msg init_branch_option_custom_hint)"

  local branch_default_index
  branch_default_index=$(init_option_find_index branch_options "$branch_prefix_default")
  if [ "$branch_default_index" -lt 0 ]; then
    branch_default_index=$(init_option_find_index branch_options "$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX")
  fi
  if [ "$branch_default_index" -lt 0 ]; then
    branch_default_index=0
  fi
  branch_default_index=$(init_option_focus_default branch_options "$branch_default_index")

  local branch_selection
  if ! branch_selection=$(prompt_choice "$(msg init_prompt_branch_prefix)" "$branch_default_index" "${branch_options[@]}"); then
    PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
    die "$(msg aborted)"
  fi

  local branch_prefix_value="$branch_prefix_default"
  case "$branch_selection" in
  __skip__)
    :
    ;;
  __custom__)
    if ! branch_prefix_value=$(prompt_input_text "$(msg init_prompt_branch_custom)" "$branch_prefix_default" 1); then
      PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"
      die "$(msg aborted)"
    fi
    branch_prefix_value=$(prompt_trim_spaces "$branch_prefix_value")
    ;;
  *)
    branch_prefix_value="$branch_selection"
    ;;
  esac

  branch_prefix_value=$(prompt_trim_spaces "$branch_prefix_value")
  branch_prefix_value="$(normalize_branch_prefix_value "$branch_prefix_value")"

  PROMPT_ASSUME_DEFAULTS="$previous_prompt_assume"

  local copy_env_enabled_str
  local install_enabled_str
  local serve_enabled_str
  local copy_env_json

  copy_env_enabled_str=$(config_bool_to_string "$copy_env_choice")
  install_enabled_str=$(config_bool_to_string "$install_enabled")
  serve_enabled_str=$(config_bool_to_string "$serve_enabled")
  copy_env_json=$(json_array_from_list "${copy_env_files[@]}")

  config_set_in_file "$target_file" "repo.path" "$repo_path_selected"
  config_set_in_file "$target_file" "add.branch-prefix" "$branch_prefix_value"
  config_set_in_file "$target_file" "add.copy-env.enabled" "$copy_env_enabled_str"
  config_set_in_file "$target_file" "add.copy-env.files" "$copy_env_json"
  config_set_in_file "$target_file" "add.install-deps.enabled" "$install_enabled_str"
  config_set_in_file "$target_file" "add.install-deps.command" "$install_command"
  config_set_in_file "$target_file" "add.serve-dev.enabled" "$serve_enabled_str"
  config_set_in_file "$target_file" "add.serve-dev.command" "$serve_command"
  config_set_in_file "$target_file" "add.serve-dev.logging-path" "$serve_logging_path"

  info "$(msg init_set_project "$repo_path_selected")"

  if [ -n "$branch_option" ]; then
    info "$(msg init_branch_option_deprecated "$branch_option")"
  fi

  if [ "$created" -eq 1 ]; then
    info "$(msg init_created_project "$slug" "$target_file")"
  fi

  local init_done_message
  init_done_message="$(msg init_done)"
  if [ -n "$init_done_message" ]; then
    info "$init_done_message"
  fi

  project_context_reset
  project_context_detect_from_cwd || true
  config_context_apply_scope
  config_cache_reset
}

remove_worktree_by_name() {
  if [ $# -ne 2 ]; then
    return 1
  fi

  local name="$1"
  local current_abs="$2"
  local target_path
  local removing_current=0

  target_path=$(worktree_path_for "$name")
  if [ ! -d "$target_path" ] && ! worktree_ref_exists "$target_path"; then
    die "$(msg worktree_not_found "$name")"
  fi

  if [ "$current_abs" = "$target_path" ]; then
    removing_current=1
  fi

  local branch=""
  if ! branch=$(worktree_branch_for_path "$target_path" 2> /dev/null); then
    branch=""
  fi

  validate_removable_worktree_branch "$name" "$branch" "$WORKTREE_BRANCH_PREFIX" || true

  if ! run_configured_hook_command "$REMOVE_PRE_COMMAND" "$PROJECT_DIR_ABS" "remove.pre" "$name" "$target_path" "$branch"; then
    die "remove pre-command failed"
  fi

  info "$(msg removing_worktree "$target_path")"
  local removal_succeeded=0
  if git_project worktree remove "$target_path" --force >&2; then
    removal_succeeded=1
  else
    if [ ! -d "$target_path" ]; then
      git_project worktree prune --expire now >&2 || true
      if ! worktree_ref_exists "$target_path"; then
        removal_succeeded=1
      fi
    fi
  fi

  if [ "$removal_succeeded" -eq 0 ]; then
    die "$(msg remove_failed)"
  fi

  if [ -n "$WT_VALIDATED_REMOVE_BRANCH" ] && git_project show-ref --verify --quiet "refs/heads/$WT_VALIDATED_REMOVE_BRANCH"; then
    git_project branch -D "$WT_VALIDATED_REMOVE_BRANCH" >&2 || true
    info "$(msg removed_branch "$WT_VALIDATED_REMOVE_BRANCH")"
  else
    log_skipped_branch_removal "$target_path" "$branch"
  fi

  info "$(msg worktree_removed "$name")"

  if [ "$removing_current" -eq 1 ]; then
    info "$(msg current_worktree_removed)"
    maybe_warn_shell_integration "$PROJECT_DIR_ABS"
    printf '%s\n' "$PROJECT_DIR_ABS"
  fi
}

cmd_merge() {
  if [ $# -ne 1 ]; then
    die "$(msg merge_requires_name)"
  fi

  local name="$1"
  local branch
  branch=$(branch_for "$name")

  ensure_within_project_directory

  local current_branch
  if current_branch=$(project_current_branch 2> /dev/null); then
    :
  else
    die "$(msg project_branch_required)"
  fi

  local base_branch="$current_branch"

  if [ -n "$(git_project status --porcelain)" ]; then
    die "$(msg merge_base_dirty)"
  fi

  if [ "$branch" = "$base_branch" ]; then
    die "$(msg merge_invalid_target "$branch" "$name" "$base_branch")"
  fi

  if ! git_project show-ref --verify --quiet "refs/heads/$branch"; then
    die "$(msg merge_branch_not_found "$branch")"
  fi

  local worktree_path
  worktree_path=$(worktree_path_for "$name")
  if [ -d "$worktree_path" ]; then
    local worktree_status
    worktree_status=$(git -C "$worktree_path" status --porcelain 2> /dev/null || true)
    if [ -n "$worktree_status" ]; then
      die "$(msg merge_feat_dirty "$worktree_path")"
    fi
  fi

  local ahead_count
  ahead_count=$(git_project rev-list --count "$base_branch..$branch" 2> /dev/null || true)
  if [ -z "$ahead_count" ]; then
    ahead_count=0
  fi

  if [ "$ahead_count" -eq 0 ]; then
    info "$(msg merge_no_commits "$branch" "$base_branch")"
    return
  fi

  info "$(msg merge_start "$branch" "$base_branch")"
  if git_project merge --no-edit "$branch" >&2; then
    info "$(msg merge_done "$branch" "$base_branch")"
    info "$(msg merge_cleanup_hint "$name")"
  else
    git_project merge --abort >&2 || true
    die "$(msg merge_conflict_abort)"
  fi
}

sync_exclude_pathspec() {
  local dir="$SERVE_DEV_LOGGING_PATH"

  if [ -z "$dir" ]; then
    return 0
  fi

  dir="${dir%/}"
  dir="${dir#/}"

  if [ -z "$dir" ]; then
    return 0
  fi

  printf ':(exclude)%s/**\n' "$dir"
}

cmd_sync() {
  if [ $# -eq 0 ]; then
    die "$(msg sync_requires_target)"
  fi

  local current_branch=""
  if ! current_branch=$(project_current_branch 2> /dev/null); then
    die "$(msg project_branch_required)"
  fi

  local base_branch="$current_branch"

  if ! git_project diff --quiet; then
    die "$(msg sync_base_dirty)"
  fi

  local sync_exclude
  sync_exclude=$(sync_exclude_pathspec)

  local base_untracked=""
  if [ -n "$sync_exclude" ]; then
    base_untracked=$(git_project ls-files --others --exclude-standard -- "$sync_exclude")
  else
    base_untracked=$(git_project ls-files --others --exclude-standard)
  fi

  if [ -n "$base_untracked" ]; then
    die "$(msg sync_base_dirty)"
  fi

  local mode_all=0
  local -a target_names=()
  local -a target_paths=()

  if [ "$1" = "all" ]; then
    if [ $# -gt 1 ]; then
      die "$(msg sync_invalid_all)"
    fi
    mode_all=1
  else
    local name
    for name in "$@"; do
      if [ "$name" = "$base_branch" ]; then
        info "$(msg sync_skip_base "$base_branch")"
        continue
      fi

      local path
      path=$(worktree_path_for "$name")
      if [ ! -d "$path" ]; then
        die "$(msg worktree_not_found "$name")"
      fi

      if [ "$path" = "$PROJECT_DIR_ABS" ]; then
        info "$(msg sync_skip_base "$base_branch")"
        continue
      fi

      target_names+=("$name")
      target_paths+=("$path")
    done
  fi

  if [ "$mode_all" -eq 1 ]; then
    local current_path=""
    while IFS= read -r line || [ -n "$line" ]; do
      if [ -z "$line" ]; then
        if [ -n "$current_path" ] && [ "$current_path" != "$PROJECT_DIR_ABS" ]; then
          local base
          base=$(basename "$current_path")
          if [[ "$base" == "$WORKTREE_NAME_PREFIX"* ]]; then
            local suffix="${base#"$WORKTREE_NAME_PREFIX"}"
            if [ -n "$suffix" ]; then
              target_names+=("$suffix")
              target_paths+=("$current_path")
            fi
          fi
        fi
        current_path=""
        continue
      fi
      case "$line" in
      worktree\ *)
        current_path="${line#worktree }"
        ;;
      esac
    done < <(git_project worktree list --porcelain)

    if [ -n "$current_path" ] && [ "$current_path" != "$PROJECT_DIR_ABS" ]; then
      local base
      base=$(basename "$current_path")
      if [[ "$base" == "$WORKTREE_NAME_PREFIX"* ]]; then
        local suffix="${base#"$WORKTREE_NAME_PREFIX"}"
        if [ -n "$suffix" ]; then
          target_names+=("$suffix")
          target_paths+=("$current_path")
        fi
      fi
    fi
  fi

  local target_count=${#target_paths[@]}
  if [ "$target_count" -eq 0 ]; then
    info "$(msg sync_no_targets)"
    return
  fi

  if git_project diff --cached --quiet; then
    info "$(msg sync_no_staged)"
    return
  fi

  local patch_file
  patch_file=$(mktemp "${TMPDIR:-/tmp}/wt-sync-XXXXXX.patch") || die "$(msg temp_file_failed)"
  trap 'rm -f "$patch_file"' RETURN EXIT

  if ! git_project diff --cached --binary > "$patch_file"; then
    rm -f "$patch_file"
    trap - RETURN EXIT
    die "$(msg sync_patch_failed)"
  fi

  local idx=0
  while [ "$idx" -lt "$target_count" ]; do
    local path="${target_paths[$idx]}"
    local name="${target_names[$idx]}"
    local status
    if [ -n "$sync_exclude" ]; then
      status=$(git -C "$path" status --porcelain -- "$sync_exclude" 2> /dev/null || true)
    else
      status=$(git -C "$path" status --porcelain 2> /dev/null || true)
    fi
    if [ -n "$status" ]; then
      rm -f "$patch_file"
      trap - RETURN EXIT
      die "$(msg sync_target_dirty "$name" "$path")"
    fi

    if ! git -C "$path" apply --check --index --3way --binary "$patch_file"; then
      rm -f "$patch_file"
      trap - RETURN EXIT
      die "$(msg sync_apply_failed "$name")"
    fi
    idx=$((idx + 1))
  done

  idx=0
  local success=0
  while [ "$idx" -lt "$target_count" ]; do
    local path="${target_paths[$idx]}"
    local name="${target_names[$idx]}"
    info "$(msg sync_apply_start "$name")"
    if git -C "$path" apply --index --3way --binary "$patch_file"; then
      success=$((success + 1))
      info "$(msg sync_apply_done "$name")"
    else
      rm -f "$patch_file"
      trap - RETURN EXIT
      die "$(msg sync_apply_failed "$name")"
    fi
    idx=$((idx + 1))
  done

  rm -f "$patch_file"
  trap - RETURN EXIT

  info "$(msg sync_done "$success")"
}

cmd_remove() {
  local assume_yes=0
  local -a names=()

  while [ $# -gt 0 ]; do
    case "$1" in
    -y | --yes | yes)
      assume_yes=1
      ;;
    -h | --help | help)
      command_usage rm
      return
      ;;
    -*)
      die "$(msg remove_unknown_option "$1")"
      ;;
    *)
      names+=("$1")
      ;;
    esac
    shift || true
  done

  local current_abs
  current_abs=$(pwd -P)

  if [ ${#names[@]} -eq 0 ]; then
    if [ "$current_abs" = "$PROJECT_DIR_ABS" ]; then
      die "$(msg cannot_remove_main)"
    fi

    local current_base
    current_base=$(basename "$current_abs")
    if [[ "$current_base" != "$WORKTREE_NAME_PREFIX"* ]]; then
      die "$(msg specify_worktree_or_inside)"
    fi

    local derived_name
    derived_name="${current_base#"$WORKTREE_NAME_PREFIX"}"

    if [ "$assume_yes" -eq 0 ]; then
      printf '%s ' "$(msg remove_confirm_prompt "$derived_name")" >&2
      read -r reply
      if [ -n "$reply" ] && [[ ! "$reply" =~ ^[Yy]$ ]]; then
        info "$(msg aborted)"
        return 1
      fi
    fi

    remove_worktree_by_name "$derived_name" "$current_abs"
    return
  fi

  local name
  for name in "${names[@]}"; do
    remove_worktree_by_name "$name" "$current_abs"
  done
}

cmd_remove_global() {
  local assume_yes=0
  local -a names=()

  while [ $# -gt 0 ]; do
    case "$1" in
    -y | --yes | yes)
      assume_yes=1
      ;;
    -h | --help | help)
      command_usage rm
      return
      ;;
    -*)
      die "$(msg remove_unknown_option "$1")"
      ;;
    *)
      names+=("$1")
      ;;
    esac
    shift || true
  done

  if [ ${#names[@]} -eq 0 ]; then
    die "$(msg command_requires_project)"
  fi

  local current_abs
  current_abs=$(pwd -P)

  local name
  for name in "${names[@]}"; do
    collect_global_worktree_matches "$name"
    local matches=${#MATCH_WORKTREE_NAMES[@]}

    if [ "$PROJECT_REGISTRY_COUNT" -eq 0 ]; then
      die "$(msg no_projects_configured)"
    fi

    if [ "$matches" -eq 0 ]; then
      info "$(msg worktree_not_found "$name")"
      continue
    fi

    local idx=0
    while [ "$idx" -lt "$matches" ]; do
      local project_index="${MATCH_WORKTREE_PROJECTS[$idx]}"
      local repo_path="${PROJECT_REGISTRY_PATHS[$project_index]}"
      local repo_slug="${PROJECT_REGISTRY_SLUGS[$project_index]}"
      local branch_prefix="${PROJECT_REGISTRY_BRANCH_PREFIXES[$project_index]}"
      local dir_prefix="${PROJECT_REGISTRY_DIR_PREFIXES[$project_index]}"
      local target_path="${MATCH_WORKTREE_PATHS[$idx]}"
      local branch_name="${MATCH_WORKTREE_BRANCHES[$idx]}"

      if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
        info "$(msg project_path_missing "$repo_slug")"
        idx=$((idx + 1))
        continue
      fi

      if [ "$assume_yes" -eq 0 ]; then
        printf '%s ' "$(msg remove_confirm_prompt_global "$name" "$repo_slug" "$target_path")" >&2
        local reply=""
        read -r reply
        if [ -n "$reply" ] && [[ ! "$reply" =~ ^[Yy]$ ]]; then
          info "$(msg aborted)"
          idx=$((idx + 1))
          continue
        fi
      fi

      validate_removable_worktree_branch "$name" "$branch_name" "$branch_prefix" || true

      info "$(msg removing_worktree "$target_path")"
      if git_at_path "$repo_path" worktree remove "$target_path" --force >&2; then
        if [ -n "$WT_VALIDATED_REMOVE_BRANCH" ]; then
          git_at_path "$repo_path" branch -D "$WT_VALIDATED_REMOVE_BRANCH" > /dev/null 2>&1 || true
        else
          log_skipped_branch_removal "$target_path" "$branch_name"
        fi
        git_at_path "$repo_path" worktree prune --expire now >&2 || true
        info "$(msg worktree_removed "$target_path")"

        if [ "$current_abs" = "$target_path" ]; then
          info "$(msg clean_switch_back)"
          maybe_warn_shell_integration "$repo_path"
          printf '%s\n' "$repo_path"
        fi
      else
        info "$(msg remove_failed "$target_path")"
      fi

      idx=$((idx + 1))
    done
  done
}

cmd_detach() {
  local force=0
  local slug=""

  while [ $# -gt 0 ]; do
    case "$1" in
    -y | --yes | --force)
      force=1
      ;;
    -h | --help | help)
      command_usage detach
      return
      ;;
    --*)
      die "$(msg detach_unknown_option "$1")"
      ;;
    *)
      if [ -n "$slug" ]; then
        die "$(msg unexpected_extra_argument "$1")"
      fi
      slug="$1"
      ;;
    esac
    shift || true
  done

  case "$CURRENT_SCOPE" in
  project)
    if [ -z "$slug" ]; then
      if [ -n "$PROJECT_SLUG" ]; then
        slug="$PROJECT_SLUG"
      elif [ -n "$PROJECT_DIR_ABS" ]; then
        slug=$(project_slug_for_path "$PROJECT_DIR_ABS" 2> /dev/null || true)
      fi
    fi
    if [ -z "$slug" ]; then
      die "$(msg detach_project_missing "unknown")"
    fi
    ;;
  global)
    project_registry_collect
    if [ "$PROJECT_REGISTRY_COUNT" -eq 0 ]; then
      die "$(msg detach_no_projects)"
    fi

    if [ -z "$slug" ]; then
      if ! project_prompt_select; then
        if [ "$PROJECT_REGISTRY_COUNT" -eq 0 ]; then
          die "$(msg detach_no_projects)"
        fi
        die "$(msg project_selection_cancelled)"
      fi

      local idx="$PROJECT_SELECTION_INDEX"
      if [ "$idx" -lt 0 ]; then
        die "$(msg project_selection_cancelled)"
      fi

      slug="${PROJECT_REGISTRY_SLUGS[$idx]}"
    fi
    ;;
  unconfigured)
    die "$(msg project_dir_unset)"
    ;;
  esac

  if [ -z "$slug" ]; then
    die "$(msg detach_project_missing "unknown")"
  fi

  local rc=0
  project_detach "$slug" "$force"
  rc=$?
  return "$rc"
}

cmd_clean() {
  [ $# -eq 0 ] || die "$(msg clean_no_args)"
  local removed=0
  local current_abs
  current_abs=$(pwd -P)
  local current_removed=0

  while IFS= read -r line; do
    case "$line" in
    worktree\ *)
      local worktree_path base suffix branch_name
      worktree_path="${line#worktree }"
      base=$(basename "$worktree_path")
      if [[ "$base" == "$WORKTREE_NAME_PREFIX"* ]]; then
        suffix="${base#"$WORKTREE_NAME_PREFIX"}"
        if [[ "$suffix" =~ ^[0-9]+$ ]]; then
          info "$(msg cleaning_worktree "$suffix")"
          if ! branch_name=$(worktree_branch_for_path "$worktree_path" 2> /dev/null); then
            branch_name=""
          fi
          validate_removable_worktree_branch "$suffix" "$branch_name" "$WORKTREE_BRANCH_PREFIX" || true
          git_project worktree remove "$worktree_path" --force >&2 || true
          if [ -n "$WT_VALIDATED_REMOVE_BRANCH" ]; then
            git_project branch -D "$WT_VALIDATED_REMOVE_BRANCH" > /dev/null 2>&1 || true
          else
            log_skipped_branch_removal "$worktree_path" "$branch_name"
          fi
          removed=$((removed + 1))
          if [ "$current_abs" = "$worktree_path" ]; then
            current_removed=1
          fi
        fi
      fi
      ;;
    esac
  done < <(git_project worktree list --porcelain)

  if [ "$removed" -gt 0 ]; then
    info "$(msg cleaned_count "$removed")"
  else
    info "$(msg cleaned_none)"
  fi

  if [ "$current_removed" -eq 1 ]; then
    info "$(msg clean_switch_back)"
    maybe_warn_shell_integration "$PROJECT_DIR_ABS"
    printf '%s\n' "$PROJECT_DIR_ABS"
  fi
}

cmd_clean_global() {
  [ $# -eq 0 ] || die "$(msg clean_no_args)"

  project_registry_collect
  if [ "$PROJECT_REGISTRY_COUNT" -eq 0 ]; then
    die "$(msg no_projects_configured)"
  fi

  local -a candidate_paths=()
  local -a candidate_suffix=()
  local -a candidate_projects=()

  local idx=0
  while [ "$idx" -lt "$PROJECT_REGISTRY_COUNT" ]; do
    local repo_path="${PROJECT_REGISTRY_PATHS[$idx]}"
    local dir_prefix="${PROJECT_REGISTRY_DIR_PREFIXES[$idx]}"
    local branch_prefix="${PROJECT_REGISTRY_BRANCH_PREFIXES[$idx]}"
    if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
      idx=$((idx + 1))
      continue
    fi

    if [ -z "$dir_prefix" ]; then
      local base
      base=$(basename "$repo_path")
      if [ -n "$base" ] && [ "$base" != "." ]; then
        dir_prefix="$base."
      fi
    fi

    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
      worktree\ *)
        local wt_path="${line#worktree }"
        local base
        base=$(basename "$wt_path")
        if [ -n "$dir_prefix" ] && [[ "$base" == "$dir_prefix"* ]]; then
          local suffix="${base#"$dir_prefix"}"
          if [[ "$suffix" =~ ^[0-9]+$ ]]; then
            candidate_paths+=("$wt_path")
            candidate_suffix+=("$suffix")
            candidate_projects+=("$idx")
          fi
        fi
        ;;
      esac
    done < <(git_at_path "$repo_path" worktree list --porcelain 2> /dev/null || true)

    idx=$((idx + 1))
  done

  local total=${#candidate_paths[@]}
  if [ "$total" -eq 0 ]; then
    info "$(msg cleaned_none)"
    return
  fi

  local removed=0
  local current_abs
  current_abs=$(pwd -P)
  local switch_back_path=""

  idx=0
  while [ "$idx" -lt "$total" ]; do
    local repo_index="${candidate_projects[$idx]}"
    local repo_path="${PROJECT_REGISTRY_PATHS[$repo_index]}"
    local repo_slug="${PROJECT_REGISTRY_SLUGS[$repo_index]}"
    local dir_prefix="${PROJECT_REGISTRY_DIR_PREFIXES[$repo_index]}"
    local branch_prefix="${PROJECT_REGISTRY_BRANCH_PREFIXES[$repo_index]}"
    local wt_path="${candidate_paths[$idx]}"
    local suffix="${candidate_suffix[$idx]}"

    local branch_name=""
    if ! branch_name=$(worktree_branch_for_path_in_repo "$repo_path" "$wt_path" 2> /dev/null); then
      branch_name=""
    fi

    if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
      idx=$((idx + 1))
      continue
    fi

    printf '%s ' "$(msg clean_confirm_prompt "$suffix" "$repo_slug" "$wt_path")" >&2
    local reply=""
    read -r reply
    if [ -z "$reply" ]; then
      reply="y"
    fi
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
      idx=$((idx + 1))
      continue
    fi

    validate_removable_worktree_branch "$suffix" "$branch_name" "$branch_prefix" || true

    info "$(msg cleaning_worktree "$suffix")"
    if git_at_path "$repo_path" worktree remove "$wt_path" --force >&2; then
      if [ -n "$WT_VALIDATED_REMOVE_BRANCH" ]; then
        git_at_path "$repo_path" branch -D "$WT_VALIDATED_REMOVE_BRANCH" > /dev/null 2>&1 || true
      else
        log_skipped_branch_removal "$wt_path" "$branch_name"
      fi
      git_at_path "$repo_path" worktree prune --expire now >&2 || true
      removed=$((removed + 1))
      if [ "$current_abs" = "$wt_path" ]; then
        switch_back_path="$repo_path"
      fi
    else
      info "$(msg remove_failed "$wt_path")"
    fi

    idx=$((idx + 1))
  done

  if [ "$removed" -gt 0 ]; then
    info "$(msg cleaned_count "$removed")"
  else
    info "$(msg cleaned_none)"
  fi

  if [ -n "$switch_back_path" ]; then
    maybe_warn_shell_integration "$switch_back_path"
    printf '%s\n' "$switch_back_path"
  fi
}

wt_main() {
  init_settings
  ensure_messages_loaded

  local command=""
  while [ $# -gt 0 ]; do
    case "$1" in
    --)
      shift
      break
      ;;
    -*)
      usage_exit 1
      ;;
    *)
      break
      ;;
    esac
    shift || true
  done

  if [ $# -eq 0 ]; then
    command="list"
  else
    command="$1"
    shift || true
  fi

  local scope
  scope=$(current_scope)
  CURRENT_SCOPE="$scope"

  if [ "$command" != "help" ] && maybe_print_command_help "$command" "$@"; then
    return
  fi

  case "$command" in
  config)
    cmd_config "$@"
    return
    ;;
  lang)
    cmd_lang "$@"
    return
    ;;
  theme)
    cmd_theme "$@"
    return
    ;;
  shell-hook)
    cmd_shell_hook "$@"
    return
    ;;
  uninstall)
    cmd_uninstall "$@"
    return
    ;;
  reinstall)
    cmd_reinstall "$@"
    return
    ;;
  init)
    cmd_init "$@"
    return
    ;;
  help)
    if [ $# -eq 0 ]; then
      usage
      return
    fi
    if [ $# -gt 1 ]; then
      die "$(msg unexpected_extra_argument "$2")"
    fi
    if ! command_usage "$1"; then
      usage_exit 1
    fi
    return
    ;;
  version)
    printf '%s\n' "$VERSION"
    return
    ;;
  esac

  case "$command" in
  list)
    case "$scope" in
    project)
      resolve_project
      cmd_list "$@"
      ;;
    global)
      cmd_list_global "$@"
      ;;
    unconfigured)
      die "$(msg project_dir_unset)"
      ;;
    esac
    ;;
  add)
    if [ "$scope" != "project" ]; then
      die "$(msg command_requires_project)"
    fi
    [ $# -ge 1 ] || die "$(msg add_requires_name)"
    resolve_project
    cmd_add "$@"
    ;;
  merge)
    if [ "$scope" != "project" ]; then
      die "$(msg command_requires_project)"
    fi
    resolve_project
    cmd_merge "$@"
    ;;
  sync)
    if [ "$scope" != "project" ]; then
      die "$(msg command_requires_project)"
    fi
    resolve_project
    cmd_sync "$@"
    ;;
  rm | remove)
    case "$scope" in
    project)
      resolve_project
      cmd_remove "$@"
      ;;
    global)
      cmd_remove_global "$@"
      ;;
    unconfigured)
      die "$(msg project_dir_unset)"
      ;;
    esac
    ;;
  detach)
    case "$scope" in
    project)
      resolve_project
      cmd_detach "$@"
      ;;
    global)
      cmd_detach "$@"
      ;;
    unconfigured)
      die "$(msg project_dir_unset)"
      ;;
    esac
    ;;
  clean)
    case "$scope" in
    project)
      resolve_project
      cmd_clean "$@"
      ;;
    global)
      cmd_clean_global "$@"
      ;;
    unconfigured)
      die "$(msg project_dir_unset)"
      ;;
    esac
    ;;
  main)
    case "$scope" in
    project)
      resolve_project
      cmd_main "$@"
      ;;
    global)
      cmd_main_global "$@"
      ;;
    unconfigured)
      die "$(msg project_dir_unset)"
      ;;
    esac
    ;;
  path)
    case "$scope" in
    project)
      resolve_project
      cmd_path "$@"
      ;;
    global)
      cmd_path_global "$@"
      ;;
    unconfigured)
      die "$(msg project_dir_unset)"
      ;;
    esac
    ;;
  *)
    case "$scope" in
    project)
      resolve_project
      cmd_path "$command" "$@"
      ;;
    global)
      cmd_path_global "$command" "$@"
      ;;
    unconfigured)
      die "$(msg project_dir_unset)"
      ;;
    esac
    ;;
  esac
}
