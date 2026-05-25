# shellcheck shell=bash

# shellcheck disable=SC2034  # Exported for commands module (wt version)
readonly VERSION="0.1.0"

readonly CONFIG_DIR_DEFAULT="$HOME/.worktree.sh"
readonly CONFIG_FILE_DEFAULT="$CONFIG_DIR_DEFAULT/config.kv"
readonly CONFIG_PROJECTS_DIR="$CONFIG_DIR_DEFAULT/projects"
readonly CONFIG_PROJECT_FILENAME="config.kv"

CONFIG_FILE="$CONFIG_FILE_DEFAULT"
CONFIG_FILE_IS_ENV_OVERRIDE=0

if [ -n "${WT_CONFIG_FILE:-}" ]; then
  CONFIG_FILE="$WT_CONFIG_FILE"
  CONFIG_FILE_IS_ENV_OVERRIDE=1
fi

CONFIG_CACHE_SOURCES=("$CONFIG_FILE")

readonly CONFIG_DEFAULT_WORKING_REPO_PATH="${HOME}/Developer/your-project"
readonly CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX="feat/"
readonly CONFIG_DEFAULT_SERVE_DEV_LOGGING_PATH="tmp"
readonly CONFIG_DEFAULT_SERVE_DEV_ENABLED=1
readonly CONFIG_DEFAULT_SERVE_DEV_READY_TIMEOUT=60
readonly CONFIG_DEFAULT_SERVE_DEV_SETTLE_TIMEOUT=5
readonly CONFIG_DEFAULT_INSTALL_DEPS_ENABLED=1
readonly CONFIG_DEFAULT_COPY_ENV_ENABLED=1
readonly CONFIG_DEFAULT_INSTALL_DEPS_COMMAND=""
readonly CONFIG_DEFAULT_SERVE_DEV_COMMAND=""
readonly CONFIG_DEFAULT_ADD_POST_COMMAND=""
readonly CONFIG_DEFAULT_REMOVE_PRE_COMMAND=""
readonly CONFIG_DEFAULT_LANGUAGE="en"
readonly CONFIG_DEFAULT_THEME="box"
readonly -a CONFIG_DEFAULT_COPY_ENV_FILES=(".env" ".env.local")
readonly -a CONFIG_BRANCH_PREFIX_FALLBACKS=("feature/" "ft/")

WORKING_REPO_PATH=""
WORKTREE_NAME_PREFIX=""
WORKTREE_BRANCH_PREFIX=""
SERVE_DEV_LOGGING_PATH=""
SERVE_DEV_ENABLED=0
SERVE_DEV_READY_TIMEOUT=0
SERVE_DEV_SETTLE_TIMEOUT=0
INSTALL_DEPS_ENABLED=0
COPY_ENV_ENABLED=0
INSTALL_DEPS_COMMAND=""
SERVE_DEV_COMMAND=""
ADD_POST_COMMAND=""
REMOVE_PRE_COMMAND=""
LANGUAGE="$CONFIG_DEFAULT_LANGUAGE"
LIST_THEME="$CONFIG_DEFAULT_THEME"
WORKING_REPO_PATH_CONFIGURED=0
COPY_ENV_FILE_SELECTION=()

: "${SCRIPT_DIR:?SCRIPT_DIR must be set before sourcing runtime.sh}"
readonly MESSAGES_FILE="$SCRIPT_DIR/messages.sh"
MESSAGES_LOADED=0
AUTO_CD_HINT_SHOWN=0
LIST_PRIMARY_WORKTREE_PATH=""
LIST_OUTPUT_WIDTH=0

PROMPT_UI_INITIALIZED=0
PROMPT_ASSUME_DEFAULTS=0
PROMPT_HAS_TTY=0
PROMPT_USE_COLOR=0
PROMPT_SUPPORTS_READLINE=0
PROMPT_COLOR_RESET=""
PROMPT_COLOR_CYAN=""
PROMPT_COLOR_GRAY=""
PROMPT_COLOR_GREEN=""
PROMPT_COLOR_BLUE=""
PROMPT_COLOR_BOLD=""
PROMPT_COLOR_UNDERLINE=""
PROMPT_FORMAT_UNDERLINE_END=""
PROMPT_LAST_LABEL=""
PROMPT_LAST_VALUE=""
PROMPT_SYMBOL_QUESTION="?"
PROMPT_SYMBOL_SUCCESS="✔"
PROMPT_SYMBOL_ARROW="›"
PROMPT_SYMBOL_CHOICE="❯"
PROMPT_SYMBOL_ELLIPSIS="…"
PROMPT_CLEANUP_RAN=0

ensure_messages_loaded() {
  if [ "$MESSAGES_LOADED" = "1" ]; then
    return
  fi

  if [ -f "$MESSAGES_FILE" ]; then
    # shellcheck disable=SC1090
    . "$MESSAGES_FILE"
    MESSAGES_LOADED=1
    return
  fi

  printf 'wt: missing messages file (%s)\n' "$MESSAGES_FILE" >&2
  exit 1
}

normalize_language() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local raw
  raw=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  raw=${raw%%.*}
  raw=${raw//-/_}

  case "$raw" in
  zh | zh_cn | zh_hans | zh_hant | zh_tw | cn | chinese | 中文)
    printf 'zh\n'
    return 0
    ;;
  en | en_us | en_gb | english | 英语)
    printf 'en\n'
    return 0
    ;;
  esac

  return 1
}

language_code_to_config_value() {
  case "${1:-}" in
  zh)
    printf 'zh\n'
    ;;
  en)
    printf 'en\n'
    ;;
  *)
    printf '%s\n' "${1:-}"
    ;;
  esac
}

normalize_theme() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local raw
  raw=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  raw=${raw// /}
  raw=${raw//-/_}

  case "$raw" in
  box | boxed | box_style | border | frame)
    printf 'box\n'
    return 0
    ;;
  sage | compact | simple | plain | legacy)
    printf 'sage\n'
    return 0
    ;;
  archer | minimal_no_path | lean)
    printf 'archer\n'
    return 0
    ;;
  esac

  return 1
}

theme_code_to_config_value() {
  case "${1:-}" in
  box)
    printf 'box\n'
    ;;
  sage)
    printf 'sage\n'
    ;;
  archer)
    printf 'archer\n'
    ;;
  *)
    printf '%s\n' "${1:-}"
    ;;
  esac
}

normalize_branch_prefix_value() {
  local value="${1:-}"
  if [ -z "$value" ]; then
    printf '%s\n' "$value"
    return 0
  fi

  if [[ "$value" != */ ]]; then
    value="${value}/"
  fi

  printf '%s\n' "$value"
}

init_language() {
  LANGUAGE="$CONFIG_DEFAULT_LANGUAGE"

  local value normalized from_config=0
  if value=$(config_get "language" 2> /dev/null); then
    if normalized=$(normalize_language "$value" 2> /dev/null); then
      LANGUAGE="$normalized"
      from_config=1
    fi
  fi

  value="${LANG:-}"
  if [ "$from_config" -eq 0 ] && [ -n "$value" ]; then
    if normalized=$(normalize_language "$value" 2> /dev/null); then
      LANGUAGE="$normalized"
    fi
  fi
}

init_theme() {
  LIST_THEME="$CONFIG_DEFAULT_THEME"

  local value normalized
  if value=$(config_get "theme" 2> /dev/null); then
    if normalized=$(normalize_theme "$value" 2> /dev/null); then
      LIST_THEME="$normalized"
    fi
  fi

  value="${WT_THEME:-}"
  if [ -n "$value" ]; then
    if normalized=$(normalize_theme "$value" 2> /dev/null); then
      LIST_THEME="$normalized"
    fi
  fi
}

detect_shell_type() {
  local shell_name="${SHELL##*/}"
  case "$shell_name" in
  bash)
    printf 'bash\n'
    ;;
  zsh)
    printf 'zsh\n'
    ;;
  *)
    printf 'none\n'
    ;;
  esac
}

msg() {
  ensure_messages_loaded
  local key
  key="${1:-}"
  shift || true
  case "$LANGUAGE" in
  zh)
    msg_zh "$key" "$@"
    ;;
  *)
    msg_en "$key" "$@"
    ;;
  esac
}

parse_bool() {
  if [ $# -ne 1 ]; then
    return 1
  fi
  local lower
  lower=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$lower" in
  1 | true | yes | on)
    printf '1\n'
    ;;
  0 | false | no | off)
    printf '0\n'
    ;;
  *)
    return 1
    ;;
  esac
}

CONFIG_CACHE_LOADED=0
CONFIG_CACHE_KEYS=()
CONFIG_CACHE_VALUES=()
CONFIG_CACHE_SOURCES=()

config_cache_reset() {
  CONFIG_CACHE_LOADED=0
  CONFIG_CACHE_KEYS=()
  CONFIG_CACHE_VALUES=()
}

config_cache_sources_set() {
  CONFIG_CACHE_SOURCES=("$@")
  config_cache_reset
}

config_cache_put() {
  if [ $# -ne 2 ]; then
    return 1
  fi

  local key="$1"
  local value="$2"
  local idx

  for idx in "${!CONFIG_CACHE_KEYS[@]}"; do
    if [ "${CONFIG_CACHE_KEYS[$idx]}" = "$key" ]; then
      # shellcheck disable=SC2004
      CONFIG_CACHE_VALUES[$idx]="$value"
      return 0
    fi
  done

  CONFIG_CACHE_KEYS+=("$key")
  CONFIG_CACHE_VALUES+=("$value")
  return 0
}

config_ensure_parent_dir() {
  if [ $# -ne 1 ]; then
    return 1
  fi
  local target="$1"
  local parent
  parent=$(dirname "$target")
  if [ -n "$parent" ] && [ ! -d "$parent" ]; then
    mkdir -p "$parent"
  fi
}

hash_prefix_six() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local input="$1"
  local hash

  hash=$(printf '%s' "$input" | git hash-object --stdin 2> /dev/null || true)
  if [ -z "$hash" ]; then
    hash=$(printf '%s' "$input" | shasum 2> /dev/null | awk '{print $1}' || true)
  fi
  if [ -z "$hash" ]; then
    hash=$(printf '%s' "$input" | md5sum 2> /dev/null | awk '{print $1}' || true)
  fi
  if [ -z "$hash" ]; then
    hash=$(printf '%s' "$input" | md5 2> /dev/null | awk '{print $4}' || true)
  fi
  if [ -z "$hash" ]; then
    local cksum_out=""
    cksum_out=$(printf '%s' "$input" | cksum 2> /dev/null || true)
    if [ -n "$cksum_out" ]; then
      hash=$(printf '%s' "$cksum_out" | awk '{printf "%08x", $1}' || true)
    fi
  fi

  if [ -z "$hash" ]; then
    hash="000000"
  fi

  printf '%s\n' "${hash:0:6}"
}

canonical_path() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local path="$1"
  if [ -z "$path" ]; then
    return 1
  fi

  local resolved
  if resolved=$(cd "$path" 2> /dev/null && /bin/pwd -P 2> /dev/null); then
    printf '%s\n' "$resolved"
  else
    printf '%s\n' "$path"
  fi
}

sanitize_project_path_fragment() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local fragment="$1"
  fragment=${fragment#/}
  fragment=$(printf '%s' "$fragment" | tr "/\\" "--")
  fragment=${fragment//./-}
  fragment=$(printf '%s' "$fragment" | tr -c 'A-Za-z0-9-' '-')
  fragment=$(printf '%s' "$fragment" | tr -s '-')
  fragment=${fragment#-}
  fragment=${fragment%-}
  if [ -z "$fragment" ]; then
    fragment="project"
  fi
  printf '%s\n' "-$fragment"
}

project_slug_for_path() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local input_path="$1"
  local abs_path="$input_path"
  if abs_path=$(cd "$input_path" 2> /dev/null && pwd -P); then
    :
  else
    abs_path="$input_path"
  fi

  local trimmed="$abs_path"
  trimmed="${trimmed#/}"
  local fragment
  fragment=$(sanitize_project_path_fragment "$trimmed") || fragment="-project"

  local slug="$fragment"

  local slug_dir=""
  slug_dir=$(project_config_dir_for_slug "$slug" 2> /dev/null || true)
  if [ -n "$slug_dir" ] && [ -d "$slug_dir" ]; then
    local config_file="$slug_dir/$CONFIG_PROJECT_FILENAME"
    local existing_path=""
    if [ -f "$config_file" ]; then
      existing_path=$(config_file_get_value "$config_file" "repo.path" 2> /dev/null || true)
    fi
    if [ -n "$existing_path" ]; then
      local existing_norm current_norm
      existing_norm=$(canonical_path "$existing_path" 2> /dev/null || printf '%s\n' "$existing_path")
      current_norm=$(canonical_path "$abs_path" 2> /dev/null || printf '%s\n' "$abs_path")
      if [ "$existing_norm" != "$current_norm" ]; then
        local hash
        hash=$(hash_prefix_six "$abs_path") || hash=""
        if [ -n "$hash" ]; then
          slug="${slug}-${hash}"
        fi
      fi
    fi
  fi

  printf '%s\n' "$slug"
}

project_config_dir_for_slug() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  printf '%s/%s\n' "$CONFIG_PROJECTS_DIR" "$1"
}

project_config_file_for_slug() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  printf '%s/%s\n' "$(project_config_dir_for_slug "$1")" "$CONFIG_PROJECT_FILENAME"
}

PROJECT_SLUG=""
PROJECT_CONFIG_FILE=""
PROJECT_CONFIG_EXISTS=0
PROJECT_DETECTED_ROOT=""

project_context_reset() {
  PROJECT_SLUG=""
  PROJECT_CONFIG_FILE=""
  PROJECT_CONFIG_EXISTS=0
  PROJECT_DETECTED_ROOT=""
  PROJECT_DIR=""
  PROJECT_DIR_ABS=""
  PROJECT_PARENT=""
}

project_context_detect_from_cwd() {
  local git_common
  git_common=$(git rev-parse --git-common-dir --path-format=absolute 2> /dev/null || true)
  if [ -z "$git_common" ]; then
    return 1
  fi

  local root="$git_common"
  root=$(dirname "$root")
  if root=$(cd "$root" 2> /dev/null && pwd -P); then
    :
  fi

  PROJECT_DETECTED_ROOT="$root"
  PROJECT_SLUG=$(project_slug_for_path "$root" 2> /dev/null || true)
  if [ -n "$PROJECT_SLUG" ]; then
    PROJECT_CONFIG_FILE=$(project_config_file_for_slug "$PROJECT_SLUG" 2> /dev/null || true)
  fi

  if [ -n "$PROJECT_CONFIG_FILE" ] && [ -f "$PROJECT_CONFIG_FILE" ]; then
    PROJECT_CONFIG_EXISTS=1
  else
    PROJECT_CONFIG_EXISTS=0
  fi

  return 0
}

config_context_apply_scope() {
  if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -eq 1 ]; then
    config_cache_sources_set "$CONFIG_FILE"
    return
  fi

  local -a sources=()

  sources+=("$CONFIG_FILE_DEFAULT")

  if [ -n "$PROJECT_CONFIG_FILE" ]; then
    sources+=("$PROJECT_CONFIG_FILE")
    CONFIG_FILE="$PROJECT_CONFIG_FILE"
  else
    CONFIG_FILE="$CONFIG_FILE_DEFAULT"
  fi

  config_cache_sources_set "${sources[@]}"
}

PROJECT_REGISTRY_SLUGS=()
PROJECT_REGISTRY_PATHS=()
PROJECT_REGISTRY_BRANCHES=()
PROJECT_REGISTRY_BRANCH_PREFIXES=()
PROJECT_REGISTRY_DIR_PREFIXES=()
PROJECT_REGISTRY_FILES=()
PROJECT_REGISTRY_DISPLAY_NAMES=()
PROJECT_REGISTRY_HEADS=()
PROJECT_REGISTRY_COUNT=0

PROJECT_SELECTION_INDEX=-1
WORKTREE_SELECTION_INDEX=-1
MATCH_WORKTREE_NAMES=()
MATCH_WORKTREE_PATHS=()
MATCH_WORKTREE_PROJECTS=()
MATCH_WORKTREE_BRANCHES=()
MATCH_WORKTREE_COUNT=0

worktree_match_reset() {
  MATCH_WORKTREE_NAMES=()
  MATCH_WORKTREE_PATHS=()
  MATCH_WORKTREE_PROJECTS=()
  MATCH_WORKTREE_BRANCHES=()
  WORKTREE_SELECTION_INDEX=-1
  MATCH_WORKTREE_COUNT=0
}

PROJECT_WORKTREE_PATHS=()
PROJECT_WORKTREE_NAMES=()
PROJECT_WORKTREE_BRANCHES=()
PROJECT_WORKTREE_BRANCH_SUFFIXES=()
PROJECT_WORKTREE_COUNT=0
PROJECT_WORKTREE_REPO_PATH=""
PROJECT_WORKTREE_REPO_EXISTS=0
PROJECT_WORKTREE_CONFIG_DIR=""
PROJECT_WORKTREE_CONFIG_FILE=""
PROJECT_WORKTREE_STATUS=""
PROJECT_WORKTREE_LAST_ERROR=""
PROJECT_WORKTREE_SLUG=""
PROJECT_REMOVE_LAST_ERROR=""

project_worktree_reset() {
  PROJECT_WORKTREE_PATHS=()
  PROJECT_WORKTREE_NAMES=()
  PROJECT_WORKTREE_BRANCHES=()
  PROJECT_WORKTREE_BRANCH_SUFFIXES=()
  PROJECT_WORKTREE_COUNT=0
  PROJECT_WORKTREE_REPO_PATH=""
  PROJECT_WORKTREE_REPO_EXISTS=0
  PROJECT_WORKTREE_CONFIG_DIR=""
  PROJECT_WORKTREE_CONFIG_FILE=""
  PROJECT_WORKTREE_STATUS=""
  PROJECT_WORKTREE_LAST_ERROR=""
  PROJECT_WORKTREE_SLUG=""
  PROJECT_REMOVE_LAST_ERROR=""
}

project_worktree_maybe_add() {
  local path="${1:-}"
  local branch="${2:-}"
  local repo_path="${3:-}"
  local dir_prefix="${4:-}"
  local branch_prefix="${5:-}"

  if [ -z "$path" ] || [ "$path" = "$repo_path" ]; then
    return 0
  fi

  local base
  base=$(basename "$path")

  local include=0
  local suffix=""

  if [ -n "$dir_prefix" ] && [[ "$base" == "$dir_prefix"* ]]; then
    suffix="${base#"$dir_prefix"}"
    include=1
  fi

  if [ "$include" -eq 0 ] && [ -n "$branch_prefix" ] && [ -n "$branch" ] && [[ "$branch" == "$branch_prefix"* ]]; then
    suffix="${branch#"$branch_prefix"}"
    include=1
  fi

  if [ "$include" -eq 0 ] && [ -z "$dir_prefix" ] && [ -z "$branch_prefix" ]; then
    suffix="$base"
    include=1
  fi

  if [ "$include" -eq 0 ]; then
    return 0
  fi

  if [ -z "$suffix" ]; then
    suffix="$base"
  fi

  local branch_suffix="$branch"
  if [ -n "$branch" ] && [ -n "$branch_prefix" ] && [[ "$branch" == "$branch_prefix"* ]]; then
    branch_suffix="${branch#"$branch_prefix"}"
  fi

  PROJECT_WORKTREE_PATHS+=("$path")
  PROJECT_WORKTREE_NAMES+=("$suffix")
  PROJECT_WORKTREE_BRANCHES+=("$branch")
  PROJECT_WORKTREE_BRANCH_SUFFIXES+=("$branch_suffix")
  PROJECT_WORKTREE_COUNT=${#PROJECT_WORKTREE_PATHS[@]}
}

tty_menu_select() {
  if [ $# -lt 3 ]; then
    return 1
  fi

  local prompt="$1"
  local invalid_message="$2"
  shift 2

  local -a options=("$@")
  local count=${#options[@]}

  if [ "$count" -eq 0 ]; then
    return 1
  fi

  if [ ! -t 0 ] || [ ! -t 2 ]; then
    return 2
  fi

  local selected=0
  local typed=""
  local error_message=""
  local last_lines=0
  local read_timeout_short=1
  local highlight_start=$'\033[36m'
  local highlight_end=$'\033[0m'
  if [ -n "${BASH_VERSINFO+x}" ]; then
    local bash_major
    bash_major="${BASH_VERSINFO[0]}"
    if [ "$bash_major" -ge 4 ]; then
      read_timeout_short='0.05'
    fi
  fi

  while true; do
    local lines=1
    printf '%s\n' "$prompt" >&2

    local idx=0
    while [ "$idx" -lt "$count" ]; do
      if [ "$idx" -eq "$selected" ]; then
        printf '%s> %s%s\n' "$highlight_start" "${options[$idx]}" "$highlight_end" >&2
      else
        printf '  %s\n' "${options[$idx]}" >&2
      fi
      lines=$((lines + 1))
      idx=$((idx + 1))
    done

    if [ -n "$error_message" ]; then
      printf '%s\n' "$error_message" >&2
      lines=$((lines + 1))
    fi

    last_lines=$lines
    error_message=""

    local key=""
    if ! IFS= read -rsn1 key; then
      printf '\n' >&2
      return 1
    fi

    if [ -z "$key" ]; then
      key=$'\n'
    fi

    case "$key" in
    $'\n' | $'\r')
      if [ -n "$typed" ]; then
        local choice=$((10#$typed))
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
          printf '\n' >&2
          printf '%d\n' "$((choice - 1))"
          return 0
        fi
        error_message="$invalid_message"
        typed=""
      else
        printf '\n' >&2
        printf '%d\n' "$selected"
        return 0
      fi
      ;;
    $'\x1b')
      local key2=""
      if ! IFS= read -rsn1 -t "$read_timeout_short" key2; then
        printf '\n' >&2
        return 1
      fi

      case "$key2" in
      '[')
        local key3=""
        if IFS= read -rsn1 -t "$read_timeout_short" key3; then
          case "$key3" in
          A)
            selected=$(((selected - 1 + count) % count))
            typed=""
            ;;
          B)
            selected=$(((selected + 1) % count))
            typed=""
            ;;
          esac
        fi
        ;;
      O)
        local key3=""
        if IFS= read -rsn1 -t "$read_timeout_short" key3; then
          case "$key3" in
          A)
            selected=$(((selected - 1 + count) % count))
            typed=""
            ;;
          B)
            selected=$(((selected + 1) % count))
            typed=""
            ;;
          esac
        fi
        ;;
      $'\x1b')
        printf '\n' >&2
        return 1
        ;;
      *)
        :
        ;;
      esac
      ;;
    $'\177')
      if [ -n "$typed" ]; then
        typed="${typed%?}"
      fi
      ;;
    [0-9])
      typed="${typed}${key}"
      local choice=$((10#$typed))
      if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
        selected=$((choice - 1))
      else
        if [ "$choice" -gt "$count" ]; then
          typed="$key"
          choice=$((10#$typed))
          if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
            selected=$((choice - 1))
          else
            error_message="$invalid_message"
            typed=""
          fi
        fi
      fi
      ;;
    q | Q)
      printf '\n' >&2
      return 1
      ;;
    k | K)
      selected=$(((selected - 1 + count) % count))
      typed=""
      ;;
    j | J)
      selected=$(((selected + 1) % count))
      typed=""
      ;;
    *) ;;
    esac

    printf '\033[%dA' "$last_lines" >&2
    printf '\033[J' >&2
  done
}

prompt_init_ui() {
  if [ "$PROMPT_UI_INITIALIZED" -eq 1 ]; then
    return
  fi

  PROMPT_UI_INITIALIZED=1
  prompt_register_cleanup_trap

  if [ -t 0 ] && [ -t 2 ]; then
    PROMPT_HAS_TTY=1
  else
    PROMPT_HAS_TTY=0
  fi

  PROMPT_SUPPORTS_READLINE=0
  PROMPT_READ_TIMEOUT_SHORT=1
  if [ -n "${BASH_VERSINFO+x}" ]; then
    if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
      PROMPT_SUPPORTS_READLINE=1
      PROMPT_READ_TIMEOUT_SHORT='0.05'
    fi
  fi

  if [ "$PROMPT_HAS_TTY" -eq 1 ] && [ -z "${NO_COLOR:-}" ]; then
    PROMPT_USE_COLOR=1
  else
    PROMPT_USE_COLOR=0
  fi

  local sgr0="" setaf6="" setaf8="" setaf2="" setaf4="" bold_seq="" smul="" rmul=""
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && command -v tput > /dev/null 2>&1; then
    sgr0=$(tput sgr0 2> /dev/null || true)
    setaf6=$(tput setaf 6 2> /dev/null || true)
    setaf8=$(tput setaf 8 2> /dev/null || true)
    setaf2=$(tput setaf 2 2> /dev/null || true)
    setaf4=$(tput setaf 4 2> /dev/null || true)
    bold_seq=$(tput bold 2> /dev/null || true)
    smul=$(tput smul 2> /dev/null || true)
    rmul=$(tput rmul 2> /dev/null || true)
  fi

  if [ -n "$sgr0" ]; then
    PROMPT_COLOR_RESET="$sgr0"
  else
    PROMPT_COLOR_RESET=$'\033[0m'
  fi

  if [ -n "$setaf6" ]; then
    PROMPT_COLOR_CYAN="$setaf6"
  else
    PROMPT_COLOR_CYAN=$'\033[36m'
  fi

  if [ -n "$setaf8" ]; then
    PROMPT_COLOR_GRAY="$setaf8"
  else
    PROMPT_COLOR_GRAY=$'\033[90m'
  fi

  if [ -n "$setaf2" ]; then
    PROMPT_COLOR_GREEN="$setaf2"
  else
    PROMPT_COLOR_GREEN=$'\033[32m'
  fi

  if [ -n "$setaf4" ]; then
    PROMPT_COLOR_BLUE="$setaf4"
  else
    PROMPT_COLOR_BLUE=$'\033[34m'
  fi

  if [ -n "$bold_seq" ]; then
    PROMPT_COLOR_BOLD="$bold_seq"
  else
    PROMPT_COLOR_BOLD=$'\033[1m'
  fi

  if [ -n "$smul" ] && [ -n "$rmul" ]; then
    PROMPT_COLOR_UNDERLINE="$smul"
    PROMPT_FORMAT_UNDERLINE_END="$rmul"
  else
    PROMPT_COLOR_UNDERLINE=$'\033[4m'
    PROMPT_FORMAT_UNDERLINE_END=$'\033[24m'
  fi

  if [ "$PROMPT_USE_COLOR" -eq 0 ]; then
    PROMPT_COLOR_RESET=""
    PROMPT_COLOR_CYAN=""
    PROMPT_COLOR_GRAY=""
    PROMPT_COLOR_GREEN=""
    PROMPT_COLOR_BLUE=""
    PROMPT_COLOR_BOLD=""
    PROMPT_COLOR_UNDERLINE=""
    PROMPT_FORMAT_UNDERLINE_END=""
  fi

  PROMPT_CURSOR_HIDDEN=0
}

prompt_wrap_for_readline() {
  local text="$1"
  if [ "$PROMPT_SUPPORTS_READLINE" -eq 1 ] && [ "$PROMPT_USE_COLOR" -eq 1 ]; then
    printf '%s' "$text" | sed -e $'s/\x1b\[[0-9;]*m/\x01&\x02/g'
    return
  fi
  printf '%s' "$text"
}

prompt_style_bold() {
  local text="$1"
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_BOLD" ]; then
    printf '%s%s%s' "$PROMPT_COLOR_BOLD" "$text" "$PROMPT_COLOR_RESET"
    return
  fi
  printf '%s' "$text"
}

prompt_style_cyan() {
  local text="$1"
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_CYAN" ]; then
    printf '%s%s%s' "$PROMPT_COLOR_CYAN" "$text" "$PROMPT_COLOR_RESET"
    return
  fi
  printf '%s' "$text"
}

prompt_style_cyan_underline() {
  local text="$1"
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_CYAN" ] && [ -n "$PROMPT_COLOR_UNDERLINE" ]; then
    printf '%s%s%s%s%s' "$PROMPT_COLOR_CYAN" "$PROMPT_COLOR_UNDERLINE" "$text" "$PROMPT_FORMAT_UNDERLINE_END" "$PROMPT_COLOR_RESET"
    return
  fi
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_CYAN" ]; then
    printf '%s%s%s' "$PROMPT_COLOR_CYAN" "$text" "$PROMPT_COLOR_RESET"
    return
  fi
  printf '%s' "$text"
}

prompt_style_green() {
  local text="$1"
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_GREEN" ]; then
    printf '%s%s%s' "$PROMPT_COLOR_GREEN" "$text" "$PROMPT_COLOR_RESET"
    return
  fi
  printf '%s' "$text"
}

prompt_style_gray() {
  local text="$1"
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_GRAY" ]; then
    printf '%s%s%s' "$PROMPT_COLOR_GRAY" "$text" "$PROMPT_COLOR_RESET"
    return
  fi
  printf '%s' "$text"
}

prompt_style_blue_bold() {
  local text="$1"
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_BLUE" ] && [ -n "$PROMPT_COLOR_BOLD" ]; then
    printf '%s%s%s%s' "$PROMPT_COLOR_BLUE" "$PROMPT_COLOR_BOLD" "$text" "$PROMPT_COLOR_RESET"
    return
  fi
  if [ "$PROMPT_USE_COLOR" -eq 1 ] && [ -n "$PROMPT_COLOR_BLUE" ]; then
    printf '%s%s%s' "$PROMPT_COLOR_BLUE" "$text" "$PROMPT_COLOR_RESET"
    return
  fi
  printf '%s' "$text"
}

prompt_style_question_symbol() {
  prompt_style_cyan "$PROMPT_SYMBOL_QUESTION"
}

prompt_style_success_symbol() {
  prompt_style_green "$PROMPT_SYMBOL_SUCCESS"
}

prompt_style_arrow_symbol() {
  prompt_style_gray "$PROMPT_SYMBOL_ARROW"
}

prompt_question_header() {
  local question="$1"
  printf '%s %s' "$(prompt_style_question_symbol)" "$(prompt_style_bold "$question")"
}

prompt_question_line() {
  local question="$1"
  local suffix="$2"
  local header
  header="$(prompt_question_header "$question")"
  if [ -n "$suffix" ]; then
    printf '%s %s %s' "$header" "$(prompt_style_arrow_symbol)" "$suffix"
  else
    printf '%s %s' "$header" "$(prompt_style_arrow_symbol)"
  fi
}

prompt_confirm_options_display() {
  local selected="$1"
  local yes_label
  local no_label
  yes_label="$(msg prompt_yes_label)"
  no_label="$(msg prompt_no_label)"

  local separator
  separator="$(prompt_style_gray ' / ')"

  local yes_display="$yes_label"
  local no_display="$no_label"

  if [ "$selected" -eq 1 ]; then
    yes_display="$(prompt_style_cyan_underline "$yes_label")"
  else
    no_display="$(prompt_style_cyan_underline "$no_label")"
  fi

  printf '%s%s%s' "$no_display" "$separator" "$yes_display"
}

prompt_success_line() {
  prompt_init_ui
  local question="$1"
  local answer_display="$2"
  local lines_to_clear="${3:-0}"

  if [ "$PROMPT_HAS_TTY" -eq 1 ] && [ "$lines_to_clear" -gt 0 ]; then
    printf '\033[%dA' "$lines_to_clear" >&2
    printf '\r\033[J' >&2
  fi

  local ellipsis="$PROMPT_SYMBOL_ELLIPSIS"
  ellipsis="$(prompt_style_gray "$ellipsis")"
  printf '%s %s %s %s\n' "$(prompt_style_success_symbol)" "$(prompt_style_bold "$question")" "$ellipsis" "$answer_display" >&2
}

prompt_join_by_space() {
  local IFS=' '
  printf '%s' "$*"
}

prompt_cleanup_trap() {
  if [ "${PROMPT_CLEANUP_RAN:-0}" -eq 1 ]; then
    return
  fi
  PROMPT_CLEANUP_RAN=1
  prompt_show_cursor
}

prompt_register_cleanup_trap() {
  if ! trap -p EXIT | grep -F 'prompt_cleanup_trap' > /dev/null 2>&1; then
    trap 'prompt_cleanup_trap' EXIT
  fi
  if ! trap -p INT | grep -F 'prompt_cleanup_trap' > /dev/null 2>&1; then
    trap 'prompt_cleanup_trap; exit 130' INT
  fi
  if ! trap -p TERM | grep -F 'prompt_cleanup_trap' > /dev/null 2>&1; then
    trap 'prompt_cleanup_trap; exit 143' TERM
  fi
  if ! trap -p HUP | grep -F 'prompt_cleanup_trap' > /dev/null 2>&1; then
    trap 'prompt_cleanup_trap; exit 129' HUP
  fi
}

prompt_hide_cursor() {
  if [ "$PROMPT_HAS_TTY" -ne 1 ]; then
    return
  fi
  prompt_register_cleanup_trap
  if [ "${PROMPT_CURSOR_HIDDEN:-0}" -eq 1 ]; then
    return
  fi
  printf '\033[?25l' >&2
  PROMPT_CURSOR_HIDDEN=1
}

prompt_show_cursor() {
  if [ "${PROMPT_CURSOR_HIDDEN:-0}" -ne 1 ]; then
    return
  fi
  printf '\033[?25h' >&2
  PROMPT_CURSOR_HIDDEN=0
}

prompt_trim_spaces() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

prompt_input_text() {
  if [ $# -lt 2 ]; then
    return 1
  fi

  local question="$1"
  local default_value="$2"
  local allow_empty="${3:-0}"

  prompt_init_ui

  local interactive=1
  if [ "$PROMPT_HAS_TTY" -ne 1 ] || [ "$PROMPT_ASSUME_DEFAULTS" -eq 1 ]; then
    interactive=0
  fi

  local answer="$default_value"
  local lines_to_clear=0
  local buffer=""

  if [ "$interactive" -eq 1 ]; then
    lines_to_clear=1
    while true; do
      local suffix=""
      if [ -n "$buffer" ]; then
        suffix="$buffer"
      elif [ -n "$default_value" ]; then
        suffix="$(prompt_style_gray "$default_value")"
      fi

      local line
      line="$(prompt_question_line "$question" "$suffix")"
      printf '\r\033[K%s' "$line" >&2

      local key=""
      if ! IFS= read -rsn1 key; then
        printf '\n' >&2
        return 1
      fi

      if [ -z "$key" ]; then
        key=$'\n'
      fi

      case "$key" in
      $'\n' | $'\r')
        printf '\n' >&2
        break
        ;;
      $'\177')
        if [ -n "$buffer" ]; then
          buffer="${buffer%?}"
        fi
        ;;
      $'\x15')
        buffer=""
        ;;
      $'\x17')
        buffer=""
        ;;
      $'\x1b')
        local key2=""
        if [ "$PROMPT_READ_TIMEOUT_SHORT" != 0 ]; then
          if IFS= read -rsn1 -t "$PROMPT_READ_TIMEOUT_SHORT" key2 && [ "$key2" = "[" ]; then
            local key3=""
            if IFS= read -rsn1 -t "$PROMPT_READ_TIMEOUT_SHORT" key3; then
              :
            fi
          fi
        else
          if IFS= read -rsn1 key2 && [ "$key2" = "[" ]; then
            local key3=""
            if IFS= read -rsn1 key3; then
              :
            fi
          fi
        fi
        ;;
      *)
        if [[ "$key" =~ [[:print:]] ]]; then
          buffer="$buffer$key"
        fi
        ;;
      esac
    done

    if [ -n "$buffer" ]; then
      answer="$(prompt_trim_spaces "$buffer")"
    else
      if [ -n "$default_value" ]; then
        answer="$default_value"
      elif [ "$allow_empty" -eq 1 ]; then
        answer=""
      else
        answer="$default_value"
      fi
    fi
  else
    if [ -z "$answer" ] && [ "$allow_empty" -ne 1 ]; then
      answer="$default_value"
    fi
  fi

  local summary_display="$answer"
  if [ -z "$summary_display" ]; then
    local empty_label
    empty_label="$(msg prompt_empty_display)"
    summary_display="$(prompt_style_gray "$empty_label")"
  fi

  prompt_success_line "$question" "$summary_display" "$lines_to_clear"

  printf '%s\n' "$answer"
}

prompt_confirm() {
  if [ $# -lt 2 ]; then
    return 1
  fi

  local question="$1"
  local default_yes="$2"
  if [ "$default_yes" -ne 0 ]; then
    default_yes=1
  fi

  prompt_init_ui

  local interactive=1
  if [ "$PROMPT_HAS_TTY" -ne 1 ] || [ "$PROMPT_ASSUME_DEFAULTS" -eq 1 ]; then
    interactive=0
  fi

  local selected="$default_yes"

  local lines_to_clear=0

  if [ "$interactive" -eq 1 ]; then
    local base=""
    base="$(prompt_question_header "$question")"
    local line=""
    prompt_hide_cursor
    while true; do
      line="${base} $(prompt_style_arrow_symbol) $(prompt_confirm_options_display "$selected")"
      printf '\r\033[K%s' "$line" >&2

      local key=""
      if ! IFS= read -rsn1 key; then
        prompt_show_cursor
        printf '\n' >&2
        return 1
      fi

      if [ -z "$key" ]; then
        key=$'\n'
      fi

      case "$key" in
      $'\n' | $'\r')
        printf '\n' >&2
        break
        ;;
      $'\x1b')
        local key2=""
        if ! IFS= read -rsn1 -t "$PROMPT_READ_TIMEOUT_SHORT" key2; then
          prompt_show_cursor
          printf '\n' >&2
          return 1
        fi
        if [ "$key2" = "[" ]; then
          local key3=""
          if ! IFS= read -rsn1 -t "$PROMPT_READ_TIMEOUT_SHORT" key3; then
            continue
          fi
          case "$key3" in
          C)
            selected=1
            ;;
          D)
            selected=0
            ;;
          esac
        fi
        ;;
      y | Y)
        selected=1
        printf '\n' >&2
        break
        ;;
      n | N)
        selected=0
        printf '\n' >&2
        break
        ;;
      q | Q)
        prompt_show_cursor
        printf '\n' >&2
        return 1
        ;;
      h | H | ?)
        continue
        ;;
      *)
        if [ "$key" = "l" ] || [ "$key" = "L" ] || [ "$key" = "1" ]; then
          selected=1
        elif [ "$key" = "0" ]; then
          selected=0
        fi
        ;;
      esac
    done
    lines_to_clear=1
  fi

  local summary=""
  summary="$(prompt_confirm_options_display "$selected")"
  prompt_success_line "$question" "$summary" "$lines_to_clear"
  prompt_show_cursor
  printf '%d\n' "$selected"
}

prompt_choice() {
  if [ $# -lt 3 ]; then
    return 1
  fi

  local question="$1"
  local default_index="$2"
  shift 2

  local -a labels=()
  local -a values=()
  local -a hints=()

  local raw=""
  for raw in "$@"; do
    local label="$raw"
    local value=""
    local hint=""

    if [[ "$raw" == *'|'* ]]; then
      label="${raw%%|*}"
      local remainder="${raw#*|}"
      if [[ "$remainder" == *'|'* ]]; then
        value="${remainder%%|*}"
        hint="${remainder#*|}"
      else
        value="$remainder"
      fi
    else
      value="$label"
    fi

    labels+=("$label")
    values+=("$value")
    hints+=("$hint")
  done

  local count=${#labels[@]}
  if [ "$count" -eq 0 ]; then
    return 1
  fi

  prompt_init_ui

  if [ -z "$default_index" ] || [ "$default_index" -lt 0 ] || [ "$default_index" -ge "$count" ]; then
    default_index=0
  fi

  local interactive=1
  if [ "$PROMPT_HAS_TTY" -ne 1 ] || [ "$PROMPT_ASSUME_DEFAULTS" -eq 1 ]; then
    interactive=0
  fi

  local selected="$default_index"

  local menu_lines=$((count + 1))

  if [ "$interactive" -eq 1 ]; then
    local hint_suffix=""
    local hint_message
    hint_message="$(msg prompt_choice_hint)"
    if [ -n "$hint_message" ]; then
      hint_suffix="$(prompt_style_gray "$hint_message")"
    fi

    local rendered=0
    prompt_hide_cursor
    while true; do
      if [ "$rendered" -ne 0 ]; then
        printf '\033[%dA' "$menu_lines" >&2
      else
        rendered=1
      fi

      local header
      header="$(prompt_question_line "$question" "$hint_suffix")"
      printf '\r\033[K%s\n' "$header" >&2

      local idx=0
      while [ "$idx" -lt "$count" ]; do
        local pointer="  "
        local option_label="${labels[$idx]}"
        local decorated_label="$option_label"
        if [ "$idx" -eq "$selected" ]; then
          pointer="$(prompt_style_cyan "$PROMPT_SYMBOL_CHOICE") "
          decorated_label="$(prompt_style_cyan_underline "$option_label")"
        fi

        local hint_line="${hints[$idx]}"
        local suffix=""
        if [ "$idx" -eq "$selected" ] && [ -n "$hint_line" ]; then
          local hint_text=" - $hint_line"
          suffix="$(prompt_style_gray "$hint_text")"
        fi

        printf '\r\033[K%s   %s%s\n' "$pointer" "$decorated_label" "$suffix" >&2
        idx=$((idx + 1))
      done

      local key=""
      if ! IFS= read -rsn1 key; then
        prompt_show_cursor
        printf '\n' >&2
        return 1
      fi

      if [ -z "$key" ]; then
        key=$'\n'
      fi

      local exit_menu=0
      local cancel_menu=0

      case "$key" in
      $'\n' | $'\r')
        exit_menu=1
        ;;
      $'\x1b')
        local key2=""
        if IFS= read -rsn1 -t "$PROMPT_READ_TIMEOUT_SHORT" key2; then
          case "$key2" in
          '[')
            local key3=""
            if IFS= read -rsn1 -t "$PROMPT_READ_TIMEOUT_SHORT" key3; then
              case "$key3" in
              A)
                selected=$(((selected - 1 + count) % count))
                ;;
              B)
                selected=$(((selected + 1) % count))
                ;;
              *)
                :
                ;;
              esac
            else
              cancel_menu=1
              exit_menu=1
            fi
            ;;
          O)
            local key3=""
            if IFS= read -rsn1 -t "$PROMPT_READ_TIMEOUT_SHORT" key3; then
              case "$key3" in
              A)
                selected=$(((selected - 1 + count) % count))
                ;;
              B)
                selected=$(((selected + 1) % count))
                ;;
              *)
                :
                ;;
              esac
            else
              cancel_menu=1
              exit_menu=1
            fi
            ;;
          $'\x1b')
            cancel_menu=1
            exit_menu=1
            ;;
          *)
            cancel_menu=1
            exit_menu=1
            ;;
          esac
        else
          cancel_menu=1
          exit_menu=1
        fi
        ;;
      $'\x03')
        cancel_menu=1
        exit_menu=1
        ;;
      k | K)
        selected=$(((selected - 1 + count) % count))
        ;;
      j | J)
        selected=$(((selected + 1) % count))
        ;;
      [0-9])
        local choice=$((10#$key))
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
          selected=$((choice - 1))
        fi
        ;;
      q | Q)
        cancel_menu=1
        exit_menu=1
        ;;
      esac

      if [ "$exit_menu" -eq 1 ]; then
        if [ "$cancel_menu" -eq 1 ]; then
          printf '\033[%dA' "$menu_lines" >&2
          printf '\033[J' >&2
          prompt_show_cursor
          return 1
        fi
        break
      fi
    done
  fi

  if [ "$interactive" -eq 1 ]; then
    printf '\033[%dA' "$menu_lines" >&2
    printf '\033[J' >&2
  fi

  PROMPT_LAST_LABEL="${labels[$selected]}"
  PROMPT_LAST_VALUE="${values[$selected]}"

  prompt_success_line "$question" "$PROMPT_LAST_LABEL"
  prompt_show_cursor
  printf '%s\n' "$PROMPT_LAST_VALUE"
}

worktree_prompt_select_global() {
  local count=${#MATCH_WORKTREE_NAMES[@]}
  if [ "$count" -eq 0 ]; then
    return 1
  fi

  if [ "$count" -eq 1 ]; then
    WORKTREE_SELECTION_INDEX=0
    return 0
  fi

  local -a option_lines=()
  local idx=0
  while [ "$idx" -lt "$count" ]; do
    local project_index="${MATCH_WORKTREE_PROJECTS[$idx]}"
    local project_name="${PROJECT_REGISTRY_DISPLAY_NAMES[$project_index]}"
    local worktree_name="${MATCH_WORKTREE_NAMES[$idx]}"
    local worktree_path="${MATCH_WORKTREE_PATHS[$idx]}"
    option_lines+=("$(msg select_worktree_option $((idx + 1)) "$worktree_name" "$project_name" "$worktree_path")")
    idx=$((idx + 1))
  done

  local prompt_base
  prompt_base="$(msg select_worktree_prompt)"
  local prompt_tty="$prompt_base"
  local nav_hint
  nav_hint="$(msg select_navigation_hint)"
  if [ -n "$nav_hint" ]; then
    prompt_tty="$prompt_tty $nav_hint"
  fi

  local invalid_message
  invalid_message="$(msg select_worktree_invalid "$count")"

  local selection_output=""
  local tty_rc=0
  if selection_output=$(tty_menu_select "$prompt_tty" "$invalid_message" "${option_lines[@]}"); then
    WORKTREE_SELECTION_INDEX="$selection_output"
    return 0
  else
    tty_rc=$?
    if [ "$tty_rc" -eq 1 ]; then
      return 1
    fi
    if [ "$tty_rc" -ne 2 ]; then
      return "$tty_rc"
    fi
  fi

  info "$prompt_base"

  idx=0
  while [ "$idx" -lt "$count" ]; do
    info "${option_lines[$idx]}"
    idx=$((idx + 1))
  done

  while true; do
    printf '%s ' "$(msg select_worktree_input "$count")" >&2
    local reply
    if ! IFS= read -r reply; then
      return 1
    fi
    if [ -z "$reply" ]; then
      info "$(msg aborted)"
      return 1
    fi
    if [[ "$reply" =~ ^[0-9]+$ ]]; then
      local choice=$((reply))
      if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
        WORKTREE_SELECTION_INDEX=$((choice - 1))
        return 0
      fi
    fi
    info "$(msg select_worktree_invalid "$count")"
  done
}

collect_global_worktree_matches() {
  local target_name="${1:-}"
  worktree_match_reset

  project_registry_collect
  if [ "$PROJECT_REGISTRY_COUNT" -eq 0 ]; then
    return 0
  fi

  if [ -z "$target_name" ]; then
    return 0
  fi

  local idx=0
  while [ "$idx" -lt "$PROJECT_REGISTRY_COUNT" ]; do
    local repo_path="${PROJECT_REGISTRY_PATHS[$idx]}"
    local prefix="${PROJECT_REGISTRY_DIR_PREFIXES[$idx]}"
    if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
      idx=$((idx + 1))
      continue
    fi

    local current_path=""
    local current_branch=""
    local line=""
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
      worktree\ *)
        if [ -n "$current_path" ]; then
          local base_prev
          base_prev=$(basename "$current_path")
          local candidate_prev=""
          if [ -n "$prefix" ] && [[ "$base_prev" == "$prefix"* ]]; then
            candidate_prev="${base_prev#"$prefix"}"
          elif [ "$base_prev" = "$target_name" ]; then
            candidate_prev="$base_prev"
          fi

          if [ -n "$candidate_prev" ] && [ "$candidate_prev" = "$target_name" ]; then
            MATCH_WORKTREE_NAMES+=("$candidate_prev")
            MATCH_WORKTREE_PATHS+=("$current_path")
            MATCH_WORKTREE_PROJECTS+=("$idx")
            MATCH_WORKTREE_BRANCHES+=("$current_branch")
          fi
        fi
        current_path="${line#worktree }"
        current_branch=""
        ;;
      branch\ *)
        current_branch="${line#branch }"
        current_branch="${current_branch#refs/heads/}"
        ;;
      "")
        if [ -n "$current_path" ]; then
          local base
          base=$(basename "$current_path")
          local candidate=""
          if [ -n "$prefix" ] && [[ "$base" == "$prefix"* ]]; then
            candidate="${base#"$prefix"}"
          elif [ "$base" = "$target_name" ]; then
            candidate="$base"
          fi

          if [ -n "$candidate" ] && [ "$candidate" = "$target_name" ]; then
            MATCH_WORKTREE_NAMES+=("$candidate")
            MATCH_WORKTREE_PATHS+=("$current_path")
            MATCH_WORKTREE_PROJECTS+=("$idx")
            MATCH_WORKTREE_BRANCHES+=("$current_branch")
          fi
        fi
        current_path=""
        current_branch=""
        ;;
      esac
    done < <(git_at_path "$repo_path" worktree list --porcelain 2> /dev/null || true)

    if [ -n "$current_path" ]; then
      local base
      base=$(basename "$current_path")
      local candidate=""
      if [ -n "$prefix" ] && [[ "$base" == "$prefix"* ]]; then
        candidate="${base#"$prefix"}"
      elif [ "$base" = "$target_name" ]; then
        candidate="$base"
      fi

      if [ -n "$candidate" ] && [ "$candidate" = "$target_name" ]; then
        MATCH_WORKTREE_NAMES+=("$candidate")
        MATCH_WORKTREE_PATHS+=("$current_path")
        MATCH_WORKTREE_PROJECTS+=("$idx")
        MATCH_WORKTREE_BRANCHES+=("$current_branch")
      fi
    fi

    idx=$((idx + 1))
  done

  MATCH_WORKTREE_COUNT=${#MATCH_WORKTREE_NAMES[@]}
  return 0
}

project_worktrees_for_slug() {
  local slug="${1:-}"

  project_worktree_reset

  if [ -z "$slug" ]; then
    PROJECT_WORKTREE_STATUS='missing-slug'
    PROJECT_WORKTREE_LAST_ERROR='slug required'
    return 1
  fi

  PROJECT_WORKTREE_SLUG="$slug"

  local config_dir
  config_dir=$(project_config_dir_for_slug "$slug" 2> /dev/null || true)
  if [ -z "$config_dir" ] || [ ! -d "$config_dir" ]; then
    PROJECT_WORKTREE_STATUS='missing-config'
    PROJECT_WORKTREE_LAST_ERROR='project config missing'
    return 1
  fi

  PROJECT_WORKTREE_CONFIG_DIR="$config_dir"

  local config_file="$config_dir/$CONFIG_PROJECT_FILENAME"
  if [ ! -f "$config_file" ]; then
    PROJECT_WORKTREE_STATUS='missing-config'
    PROJECT_WORKTREE_LAST_ERROR='project config missing'
    return 1
  fi

  PROJECT_WORKTREE_CONFIG_FILE="$config_file"

  local repo_path
  repo_path=$(config_file_get_value "$config_file" "repo.path" 2> /dev/null || true)
  PROJECT_WORKTREE_REPO_PATH="$repo_path"
  if [ -z "$repo_path" ]; then
    PROJECT_WORKTREE_STATUS='repo-missing'
    PROJECT_WORKTREE_LAST_ERROR='repo.path not set'
    PROJECT_WORKTREE_REPO_EXISTS=0
    return 0
  fi

  if [ -d "$repo_path" ]; then
    PROJECT_WORKTREE_REPO_EXISTS=1
  else
    PROJECT_WORKTREE_STATUS='repo-missing'
    PROJECT_WORKTREE_LAST_ERROR='repository path missing'
    PROJECT_WORKTREE_REPO_EXISTS=0
    return 0
  fi

  local branch_prefix
  branch_prefix=$(config_file_get_value "$config_file" "add.branch-prefix" 2> /dev/null || true)
  branch_prefix="$(normalize_branch_prefix_value "$branch_prefix")"
  if [ -z "$branch_prefix" ]; then
    branch_prefix="$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX"
  fi

  local dir_prefix=""
  local repo_base
  repo_base=$(basename "$repo_path")
  if [ -n "$repo_base" ] && [ "$repo_base" != "." ]; then
    dir_prefix="$repo_base."
  fi

  PROJECT_WORKTREE_STATUS='ok'

  local list_output=""
  if ! list_output=$(git_at_path "$repo_path" worktree list --porcelain 2>&1); then
    PROJECT_WORKTREE_STATUS='git-error'
    PROJECT_WORKTREE_LAST_ERROR="$list_output"
    return 1
  fi

  local line="" entry_path="" entry_branch=""
  while IFS= read -r line; do
    if [ -z "$line" ]; then
      if [ -n "$entry_path" ]; then
        project_worktree_maybe_add "$entry_path" "$entry_branch" "$repo_path" "$dir_prefix" "$branch_prefix"
      fi
      entry_path=""
      entry_branch=""
      continue
    fi

    case "$line" in
    worktree\ *)
      if [ -n "$entry_path" ]; then
        project_worktree_maybe_add "$entry_path" "$entry_branch" "$repo_path" "$dir_prefix" "$branch_prefix"
      fi
      entry_path="${line#worktree }"
      entry_branch=""
      ;;
    branch\ *)
      entry_branch="${line#branch }"
      entry_branch="${entry_branch#refs/heads/}"
      ;;
    esac
  done < <(printf '%s\n' "$list_output")

  if [ -n "$entry_path" ]; then
    project_worktree_maybe_add "$entry_path" "$entry_branch" "$repo_path" "$dir_prefix" "$branch_prefix"
  fi

  return 0
}

project_remove_worktree() {
  local path="${1:-}"
  local branch="${2:-}"

  PROJECT_REMOVE_LAST_ERROR=""

  local repo_path="$PROJECT_WORKTREE_REPO_PATH"
  if [ -z "$repo_path" ] || [ "$PROJECT_WORKTREE_REPO_EXISTS" -ne 1 ]; then
    PROJECT_REMOVE_LAST_ERROR='repository unavailable'
    return 1
  fi

  if [ -z "$path" ]; then
    PROJECT_REMOVE_LAST_ERROR='worktree path missing'
    return 1
  fi

  local hook_name=""
  if [ -n "$branch" ]; then
    hook_name="${branch##*/}"
  else
    hook_name="$(basename "$path")"
    if [ -n "$WORKTREE_NAME_PREFIX" ] && [[ "$hook_name" == "$WORKTREE_NAME_PREFIX"* ]]; then
      hook_name="${hook_name#"$WORKTREE_NAME_PREFIX"}"
    fi
  fi

  if ! run_configured_hook_command "$REMOVE_PRE_COMMAND" "$PROJECT_DIR_ABS" "remove.pre" "$hook_name" "$path" "$branch"; then
    PROJECT_REMOVE_LAST_ERROR='remove pre-command failed'
    return 1
  fi

  local removal_failure=0
  local removal_output=""

  if removal_output=$(git_at_path "$repo_path" worktree remove "$path" --force 2>&1); then
    :
  else
    removal_failure=1
    PROJECT_REMOVE_LAST_ERROR="$removal_output"
  fi

  if [ "$removal_failure" -eq 1 ] && [ ! -d "$path" ]; then
    git_at_path "$repo_path" worktree prune --expire now > /dev/null 2>&1 || true
    local verify_output
    verify_output=$(git_at_path "$repo_path" worktree list --porcelain 2>&1 || true)
    if ! printf '%s\n' "$verify_output" | grep -Fq "worktree $path"; then
      removal_failure=0
      PROJECT_REMOVE_LAST_ERROR=""
    fi
  fi

  if [ "$removal_failure" -eq 1 ]; then
    if [ -n "$PROJECT_REMOVE_LAST_ERROR" ]; then
      local first_line
      IFS=$'\n' read -r first_line _rest <<< "$PROJECT_REMOVE_LAST_ERROR"
      PROJECT_REMOVE_LAST_ERROR="$first_line"
    else
      PROJECT_REMOVE_LAST_ERROR='worktree remove failed'
    fi
    return 1
  fi

  if [ -n "$branch" ] && git_at_path "$repo_path" show-ref --verify --quiet "refs/heads/$branch"; then
    if protected_worktree_branch "$branch"; then
      info "$(msg remove_branch_skip_protected "$path" "$branch" "$branch")"
    elif git_at_path "$repo_path" branch -D "$branch" > /dev/null 2>&1; then
      info "$(msg removed_branch "$branch")"
    fi
  fi

  return 0
}

project_detach() {
  if [ $# -lt 1 ]; then
    return 1
  fi

  local slug="$1"
  local force="${2:-0}"

  if ! project_worktrees_for_slug "$slug"; then
    case "$PROJECT_WORKTREE_STATUS" in
    missing-config | missing-slug)
      info "$(msg detach_project_missing "$slug")"
      return 1
      ;;
    git-error)
      local err="$PROJECT_WORKTREE_LAST_ERROR"
      if [ -n "$err" ]; then
        info "$(msg git_command_failed "$PROJECT_WORKTREE_REPO_PATH")"
        info "$err"
      fi
      return 1
      ;;
    *)
      info "$(msg detach_project_missing "$slug")"
      return 1
      ;;
    esac
  fi

  if [ -z "$PROJECT_WORKTREE_CONFIG_DIR" ] || [ ! -d "$PROJECT_WORKTREE_CONFIG_DIR" ]; then
    PROJECT_WORKTREE_STATUS='missing-config'
    return 1
  fi

  if [ -z "$PROJECT_WORKTREE_CONFIG_FILE" ] || [ ! -f "$PROJECT_WORKTREE_CONFIG_FILE" ]; then
    PROJECT_WORKTREE_STATUS='missing-config'
    return 1
  fi

  if [ "$PROJECT_WORKTREE_STATUS" = "repo-missing" ]; then
    info "$(msg project_path_missing "$slug")"
  fi

  local removed_count=0
  local failure_count=0
  local skipped_count=0
  local aborted=0
  local current_removed=0
  local current_dir
  current_dir=$(pwd -P 2> /dev/null || pwd)
  local -a failure_paths=()
  local -a failure_reasons=()

  if [ "$PROJECT_WORKTREE_REPO_EXISTS" -eq 1 ] && [ "$PROJECT_WORKTREE_COUNT" -gt 0 ]; then
    local idx=0
    while [ "$idx" -lt "$PROJECT_WORKTREE_COUNT" ]; do
      local path="${PROJECT_WORKTREE_PATHS[$idx]}"
      local branch="${PROJECT_WORKTREE_BRANCHES[$idx]}"

      if [ "$force" -ne 1 ]; then
        printf '%s ' "$(msg detach_prompt_worktree "$path")" >&2
        local reply=""
        if ! IFS= read -r reply; then
          aborted=1
          skipped_count=$((PROJECT_WORKTREE_COUNT - idx))
          break
        fi
        if [ -n "$reply" ] && [[ ! "$reply" =~ ^[Yy]$ ]]; then
          aborted=1
          skipped_count=$((PROJECT_WORKTREE_COUNT - idx))
          break
        fi
      fi

      info "$(msg removing_worktree "$path")"
      if project_remove_worktree "$path" "$branch"; then
        removed_count=$((removed_count + 1))
        info "$(msg worktree_removed "$path")"
        if [ "$current_dir" = "$path" ]; then
          current_removed=1
        fi
      else
        failure_count=$((failure_count + 1))
        local reason="$PROJECT_REMOVE_LAST_ERROR"
        if [ -z "$reason" ]; then
          reason='unknown error'
        fi
        failure_paths+=("$path")
        failure_reasons+=("$reason")
        info "$(msg detach_remove_failed "$path" "$reason")"
      fi

      idx=$((idx + 1))
    done
  fi

  if [ "$aborted" -eq 1 ]; then
    info "$(msg detach_abort_user)"
    info "$(msg detach_summary_removed "$removed_count")"
    if [ "$failure_count" -gt 0 ]; then
      local failure_idx
      for failure_idx in "${!failure_paths[@]}"; do
        info "$(msg detach_summary_failed "${failure_paths[$failure_idx]}" "${failure_reasons[$failure_idx]}")"
      done
    fi
    if [ "$skipped_count" -gt 0 ]; then
      info "$(msg detach_summary_skipped "$skipped_count")"
    fi
    return 1
  fi

  if [ -d "$PROJECT_WORKTREE_CONFIG_DIR" ]; then
    if [ "$force" -ne 1 ]; then
      printf '%s ' "$(msg detach_prompt_project "$slug")" >&2
      local reply=""
      if ! IFS= read -r reply; then
        info "$(msg detach_abort_user)"
        return 1
      fi
      if [ -n "$reply" ] && [[ ! "$reply" =~ ^[Yy]$ ]]; then
        info "$(msg detach_abort_user)"
        info "$(msg detach_summary_removed "$removed_count")"
        if [ "$failure_count" -gt 0 ]; then
          local failure_idx
          for failure_idx in "${!failure_paths[@]}"; do
            info "$(msg detach_summary_failed "${failure_paths[$failure_idx]}" "${failure_reasons[$failure_idx]}")"
          done
        fi
        return 1
      fi
    fi

    if ! rm -rf "$PROJECT_WORKTREE_CONFIG_DIR"; then
      info "$(msg detach_remove_failed "$PROJECT_WORKTREE_CONFIG_DIR" "rm -rf failed")"
      return 1
    fi
  fi

  config_cache_reset
  project_context_reset
  project_context_detect_from_cwd || true
  if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -eq 0 ]; then
    config_context_apply_scope
  fi

  info "$(msg detach_summary_removed "$removed_count")"

  if [ "$failure_count" -gt 0 ]; then
    local failure_idx
    for failure_idx in "${!failure_paths[@]}"; do
      info "$(msg detach_summary_failed "${failure_paths[$failure_idx]}" "${failure_reasons[$failure_idx]}")"
    done
  fi

  info "$(msg detach_done "$slug")"

  if [ "$current_removed" -eq 1 ] && [ -n "$PROJECT_WORKTREE_REPO_PATH" ]; then
    info "$(msg clean_switch_back)"
    maybe_warn_shell_integration "$PROJECT_WORKTREE_REPO_PATH"
    printf '%s\n' "$PROJECT_WORKTREE_REPO_PATH"
  fi

  if [ "$failure_count" -gt 0 ]; then
    return 2
  fi

  return 0
}

project_registry_reset() {
  PROJECT_REGISTRY_SLUGS=()
  PROJECT_REGISTRY_PATHS=()
  PROJECT_REGISTRY_BRANCHES=()
  PROJECT_REGISTRY_BRANCH_PREFIXES=()
  PROJECT_REGISTRY_DIR_PREFIXES=()
  PROJECT_REGISTRY_FILES=()
  PROJECT_REGISTRY_DISPLAY_NAMES=()
  PROJECT_REGISTRY_HEADS=()
  PROJECT_REGISTRY_COUNT=0
}

project_registry_collect() {
  project_registry_reset

  [ -d "$CONFIG_PROJECTS_DIR" ] || return 0

  local slug_dir=""
  local slug=""
  local config_file=""
  local repo_path=""

  for slug_dir in "$CONFIG_PROJECTS_DIR"/*; do
    [ -d "$slug_dir" ] || continue
    slug=$(basename "$slug_dir")
    config_file="$slug_dir/$CONFIG_PROJECT_FILENAME"
    [ -f "$config_file" ] || continue

    repo_path=$(config_file_get_value "$config_file" "repo.path" 2> /dev/null || true)
    if [ -n "$repo_path" ]; then
      repo_path=$(canonical_path "$repo_path" 2> /dev/null || printf '%s\n' "$repo_path")
    fi
    local branch_prefix
    branch_prefix=$(config_file_get_value "$config_file" "add.branch-prefix" 2> /dev/null || true)
    branch_prefix="$(normalize_branch_prefix_value "$branch_prefix")"

    local dir_prefix=""
    if [ -n "$repo_path" ]; then
      local base
      base=$(basename "$repo_path")
      if [ -n "$base" ] && [ "$base" != "." ]; then
        dir_prefix="$base."
      fi
    fi

    local display_branch=""
    local head_short=""
    if [ -n "$repo_path" ] && [ -d "$repo_path" ]; then
      head_short=$(git_at_path "$repo_path" rev-parse --short HEAD 2> /dev/null || true)
      local branch_current
      branch_current=$(git_at_path "$repo_path" rev-parse --abbrev-ref HEAD 2> /dev/null || true)
      if [ -n "$branch_current" ] && [ "$branch_current" != "HEAD" ]; then
        display_branch="$branch_current"
      fi
    fi
    PROJECT_REGISTRY_SLUGS+=("$slug")
    PROJECT_REGISTRY_PATHS+=("$repo_path")
    PROJECT_REGISTRY_BRANCHES+=("$display_branch")
    PROJECT_REGISTRY_BRANCH_PREFIXES+=("$branch_prefix")
    PROJECT_REGISTRY_DIR_PREFIXES+=("$dir_prefix")
    PROJECT_REGISTRY_FILES+=("$config_file")
    local display_name=""
    if [ -n "$repo_path" ]; then
      display_name=$(basename "$repo_path")
      if [ -z "$display_name" ] || [ "$display_name" = "." ]; then
        display_name=""
      fi
    fi
    if [ -z "$display_name" ]; then
      display_name="$slug"
    fi
    PROJECT_REGISTRY_DISPLAY_NAMES+=("$display_name")
    PROJECT_REGISTRY_HEADS+=("$head_short")
  done

  PROJECT_REGISTRY_COUNT=${#PROJECT_REGISTRY_SLUGS[@]}
  return 0
}

project_prompt_select() {
  PROJECT_SELECTION_INDEX=-1
  project_registry_collect

  local count=$PROJECT_REGISTRY_COUNT
  if [ "$count" -eq 0 ]; then
    return 1
  fi

  if [ "$count" -eq 1 ]; then
    PROJECT_SELECTION_INDEX=0
    return 0
  fi

  local -a option_lines=()
  local idx=0
  while [ "$idx" -lt "$count" ]; do
    local display_path="${PROJECT_REGISTRY_PATHS[$idx]}"
    local display_name="${PROJECT_REGISTRY_DISPLAY_NAMES[$idx]}"
    local branch_meta="${PROJECT_REGISTRY_BRANCHES[$idx]}"
    local head_meta="${PROJECT_REGISTRY_HEADS[$idx]}"
    local meta=""
    if [ -n "$branch_meta" ]; then
      meta="$branch_meta"
    fi
    if [ -n "$head_meta" ]; then
      if [ -n "$meta" ]; then
        meta="$meta @ $head_meta"
      else
        meta="$head_meta"
      fi
    fi
    option_lines+=("$(msg select_project_option $((idx + 1)) "$display_name" "$meta" "$display_path")")
    idx=$((idx + 1))
  done

  local prompt_base
  prompt_base="$(msg select_project_prompt)"
  local prompt_tty="$prompt_base"
  local nav_hint
  nav_hint="$(msg select_navigation_hint)"
  if [ -n "$nav_hint" ]; then
    prompt_tty="$prompt_tty $nav_hint"
  fi

  local invalid_message
  invalid_message="$(msg select_project_invalid "$count")"

  local selection_output=""
  local tty_rc=0
  if selection_output=$(tty_menu_select "$prompt_tty" "$invalid_message" "${option_lines[@]}"); then
    PROJECT_SELECTION_INDEX="$selection_output"
    return 0
  else
    tty_rc=$?
    if [ "$tty_rc" -eq 1 ]; then
      return 1
    fi
    if [ "$tty_rc" -ne 2 ]; then
      return "$tty_rc"
    fi
  fi

  info "$prompt_base"

  idx=0
  while [ "$idx" -lt "$count" ]; do
    info "${option_lines[$idx]}"
    idx=$((idx + 1))
  done

  while true; do
    printf '%s ' "$(msg select_project_input "$count")" >&2
    local reply
    if ! IFS= read -r reply; then
      return 1
    fi
    if [ -z "$reply" ]; then
      info "$(msg aborted)"
      return 1
    fi
    if [[ "$reply" =~ ^[0-9]+$ ]]; then
      local choice=$((reply))
      if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
        PROJECT_SELECTION_INDEX=$((choice - 1))
        return 0
      fi
    fi
    info "$(msg select_project_invalid "$count")"
  done
}

current_scope() {
  if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -eq 1 ]; then
    printf 'project\n'
    return 0
  fi

  if [ "$PROJECT_CONFIG_EXISTS" -eq 1 ]; then
    printf 'project\n'
    return 0
  fi

  if [ -n "$PROJECT_DETECTED_ROOT" ]; then
    printf 'unconfigured\n'
    return 0
  fi

  printf 'global\n'
  return 0
}

config_cache_load() {
  if [ "$CONFIG_CACHE_LOADED" = "1" ]; then
    return 0
  fi

  CONFIG_CACHE_KEYS=()
  CONFIG_CACHE_VALUES=()

  if [ ${#CONFIG_CACHE_SOURCES[@]} -eq 0 ]; then
    if [ -n "$CONFIG_FILE" ]; then
      CONFIG_CACHE_SOURCES=("$CONFIG_FILE")
    fi
  fi

  local source
  for source in "${CONFIG_CACHE_SOURCES[@]}"; do
    [ -n "$source" ] || continue

    if [ ! -f "$source" ]; then
      if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -eq 1 ] && [ "$source" = "$CONFIG_FILE" ]; then
        die "$(msg config_file_missing "$CONFIG_FILE")"
      fi
      continue
    fi

    local line key value
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
      '' | '#'*)
        continue
        ;;
      esac
      if [[ "$line" != *"="* ]]; then
        continue
      fi
      key="${line%%=*}"
      value="${line#*=}"
      [ -n "$key" ] || continue
      config_cache_put "$key" "$value"
    done < "$source"
  done

  CONFIG_CACHE_LOADED=1
  return 0
}

config_file_get_value() {
  if [ $# -ne 2 ]; then
    return 1
  fi

  local file="$1"
  local key="$2"

  [ -f "$file" ] || return 1

  local line current
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
    '' | '#'*)
      continue
      ;;
    esac
    if [[ "$line" != *"="* ]]; then
      continue
    fi
    current="${line%%=*}"
    if [ "$current" = "$key" ]; then
      printf '%s\n' "${line#*=}"
      return 0
    fi
  done < "$file"

  return 1
}

config_get() {
  local key="${1:-}"
  [ -n "$key" ] || return 1

  if ! config_cache_load; then
    return 1
  fi

  local idx
  for idx in "${!CONFIG_CACHE_KEYS[@]}"; do
    if [ "${CONFIG_CACHE_KEYS[$idx]}" = "$key" ]; then
      printf '%s\n' "${CONFIG_CACHE_VALUES[$idx]}"
      return 0
    fi
  done

  return 1
}

config_default_value() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local key="$1"
  case "$key" in
  language)
    printf '%s\n' "$CONFIG_DEFAULT_LANGUAGE"
    ;;
  theme)
    printf '%s\n' "$CONFIG_DEFAULT_THEME"
    ;;
  repo.path)
    printf '%s\n' "$CONFIG_DEFAULT_WORKING_REPO_PATH"
    ;;
  add.branch-prefix)
    printf '%s\n' "$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX"
    ;;
  add.copy-env.enabled)
    config_bool_to_string "$CONFIG_DEFAULT_COPY_ENV_ENABLED"
    ;;
  add.copy-env.files)
    json_array_from_list "${CONFIG_DEFAULT_COPY_ENV_FILES[@]}"
    ;;
  add.install-deps.enabled)
    config_bool_to_string "$CONFIG_DEFAULT_INSTALL_DEPS_ENABLED"
    ;;
  add.install-deps.command)
    printf '%s\n' "$CONFIG_DEFAULT_INSTALL_DEPS_COMMAND"
    ;;
  add.post-command)
    printf '%s\n' "$CONFIG_DEFAULT_ADD_POST_COMMAND"
    ;;
  add.serve-dev.enabled)
    config_bool_to_string "$CONFIG_DEFAULT_SERVE_DEV_ENABLED"
    ;;
  add.serve-dev.command)
    printf '%s\n' "$CONFIG_DEFAULT_SERVE_DEV_COMMAND"
    ;;
  add.serve-dev.logging-path)
    printf '%s\n' "$CONFIG_DEFAULT_SERVE_DEV_LOGGING_PATH"
    ;;
  add.serve-dev.ready-timeout)
    printf '%s\n' "$CONFIG_DEFAULT_SERVE_DEV_READY_TIMEOUT"
    ;;
  add.serve-dev.settle-timeout)
    printf '%s\n' "$CONFIG_DEFAULT_SERVE_DEV_SETTLE_TIMEOUT"
    ;;
  remove.pre-command)
    printf '%s\n' "$CONFIG_DEFAULT_REMOVE_PRE_COMMAND"
    ;;
  *)
    return 1
    ;;
  esac
}

config_get_or_default() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local key="$1"
  local value

  if value=$(config_get "$key" 2> /dev/null); then
    printf '%s\n' "$value"
    return 0
  fi

  if value=$(config_default_value "$key" 2> /dev/null); then
    printf '%s\n' "$value"
    return 0
  fi

  return 1
}

config_set() {
  if [ $# -ne 2 ]; then
    die "$(msg config_set_requires)"
  fi

  local key="$1"
  local value="$2"

  if [ -z "$CONFIG_FILE" ]; then
    die "$(msg config_update_failed)"
  fi

  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/wt-config.XXXXXX") || die "$(msg config_update_failed)"

  local updated=0
  local line current_key
  if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" != *"="* ]]; then
        printf '%s\n' "$line" >> "$tmp"
        continue
      fi

      current_key="${line%%=*}"
      if [ -z "$current_key" ]; then
        continue
      fi

      if [ "$current_key" = "$key" ]; then
        printf '%s=%s\n' "$key" "$value" >> "$tmp"
        updated=1
      else
        printf '%s\n' "$line" >> "$tmp"
      fi
    done < "$CONFIG_FILE"
  fi

  if [ "$updated" -eq 0 ]; then
    printf '%s=%s\n' "$key" "$value" >> "$tmp"
  fi

  if config_ensure_parent_dir "$CONFIG_FILE" && mv "$tmp" "$CONFIG_FILE" 2> /dev/null; then
    chmod 600 "$CONFIG_FILE" 2> /dev/null || true
    config_cache_reset
    return 0
  fi

  rm -f "$tmp"
  die "$(msg config_update_failed)"
}

config_set_in_file() {
  if [ $# -ne 3 ]; then
    return 1
  fi

  local target_file="$1"
  local key="$2"
  local value="$3"

  local original_file="$CONFIG_FILE"
  local original_override="$CONFIG_FILE_IS_ENV_OVERRIDE"
  local -a original_sources=("${CONFIG_CACHE_SOURCES[@]}")

  CONFIG_FILE_IS_ENV_OVERRIDE=0
  CONFIG_FILE="$target_file"
  config_cache_sources_set "$target_file"

  config_set "$key" "$value"

  CONFIG_FILE="$original_file"
  CONFIG_FILE_IS_ENV_OVERRIDE="$original_override"
  config_cache_sources_set "${original_sources[@]}"
  return 0
}

config_unset() {
  if [ $# -ne 1 ]; then
    die "$(msg config_unset_requires)"
  fi

  local key="$1"

  if [ -z "$CONFIG_FILE" ]; then
    die "$(msg config_file_missing "$CONFIG_FILE")"
  fi

  local default_value=""
  local has_default=0
  if default_value=$(config_default_value "$key" 2> /dev/null); then
    has_default=1
  fi

  local tmp
  tmp=$(mktemp "${TMPDIR:-/tmp}/wt-config.XXXXXX") || die "$(msg config_update_failed)"

  local found=0
  local line current_key
  if [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" != *"="* ]]; then
        printf '%s\n' "$line" >> "$tmp"
        continue
      fi

      current_key="${line%%=*}"
      if [ -z "$current_key" ]; then
        continue
      fi

      if [ "$current_key" = "$key" ]; then
        found=1
        if [ "$has_default" -eq 1 ]; then
          printf '%s=%s\n' "$key" "$default_value" >> "$tmp"
        fi
      else
        printf '%s\n' "$line" >> "$tmp"
      fi
    done < "$CONFIG_FILE"
  fi

  if [ "$found" -eq 0 ]; then
    if [ "$has_default" -eq 1 ]; then
      printf '%s=%s\n' "$key" "$default_value" >> "$tmp"
    else
      rm -f "$tmp"
      die "$(msg config_key_not_set "$key")"
    fi
  fi

  if config_ensure_parent_dir "$CONFIG_FILE" && mv "$tmp" "$CONFIG_FILE" 2> /dev/null; then
    chmod 600 "$CONFIG_FILE" 2> /dev/null || true
    config_cache_reset
    return 0
  fi

  rm -f "$tmp"
  die "$(msg config_update_failed)"
}

json_escape_string() {
  local input="$1"
  input="${input//\\/\\\\}"
  input="${input//\"/\\\"}"
  input="${input//$'\n'/\\n}"
  input="${input//$'\r'/\\r}"
  input="${input//$'\t'/\\t}"
  printf '%s' "$input"
}

json_array_from_list() {
  if [ $# -eq 0 ]; then
    printf '[]\n'
    return
  fi

  local json="["
  local first=1
  local item escaped
  for item in "$@"; do
    escaped=$(json_escape_string "$item")
    if [ $first -eq 0 ]; then
      json+=", "
    fi
    json+="\"$escaped\""
    first=0
  done
  json+=']'
  printf '%s\n' "$json"
}

init_settings() {
  init_settings_defaults

  project_context_reset
  project_context_detect_from_cwd || true

  if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -eq 0 ]; then
    if [ "$PROJECT_CONFIG_EXISTS" -ne 1 ] && [ -n "$PROJECT_CONFIG_FILE" ] && [ -f "$PROJECT_CONFIG_FILE" ]; then
      PROJECT_CONFIG_EXISTS=1
    fi
  fi

  if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -eq 1 ]; then
    config_cache_sources_set "$CONFIG_FILE"
  else
    config_context_apply_scope
  fi

  init_settings_apply_from_sources
  init_language
  init_theme
}

init_settings_apply_from_sources() {
  if ! config_cache_load; then
    return 1
  fi

  local value
  local bool_val

  if value=$(config_get "language" 2> /dev/null); then
    [ -n "$value" ] && LANGUAGE="$value"
  fi

  if value=$(config_get "theme" 2> /dev/null); then
    [ -n "$value" ] && LIST_THEME="$value"
  fi

  if value=$(config_get "repo.path" 2> /dev/null); then
    if [ -n "$value" ]; then
      WORKING_REPO_PATH=$(canonical_path "$value" 2> /dev/null || printf '%s\n' "$value")
      WORKING_REPO_PATH_CONFIGURED=1
    fi
  elif [ -n "$PROJECT_DETECTED_ROOT" ]; then
    WORKING_REPO_PATH=$(canonical_path "$PROJECT_DETECTED_ROOT" 2> /dev/null || printf '%s\n' "$PROJECT_DETECTED_ROOT")
  fi

  if [ -n "$WORKING_REPO_PATH" ]; then
    local prefix_base
    prefix_base=$(basename "$WORKING_REPO_PATH")
    if [ -n "$prefix_base" ] && [ "$prefix_base" != "." ]; then
      WORKTREE_NAME_PREFIX="$prefix_base."
    fi
  fi

  if value=$(config_get "add.branch-prefix" 2> /dev/null); then
    if [ -n "$value" ]; then
      WORKTREE_BRANCH_PREFIX="$(normalize_branch_prefix_value "$value")"
    fi
  fi

  if value=$(config_get "add.serve-dev.logging-path" 2> /dev/null); then
    [ -n "$value" ] && SERVE_DEV_LOGGING_PATH="$value"
  fi

  if value=$(config_get "add.serve-dev.enabled" 2> /dev/null); then
    if bool_val=$(parse_bool "$value" 2> /dev/null); then
      SERVE_DEV_ENABLED="$bool_val"
    fi
  fi

  if value=$(config_get "add.serve-dev.command" 2> /dev/null); then
    SERVE_DEV_COMMAND="$value"
  fi

  if value=$(config_get "add.serve-dev.ready-timeout" 2> /dev/null); then
    [ -n "$value" ] && SERVE_DEV_READY_TIMEOUT="$value"
  fi

  if value=$(config_get "add.serve-dev.settle-timeout" 2> /dev/null); then
    [ -n "$value" ] && SERVE_DEV_SETTLE_TIMEOUT="$value"
  fi

  if value=$(config_get "add.post-command" 2> /dev/null); then
    ADD_POST_COMMAND="$value"
  fi

  if value=$(config_get "add.install-deps.enabled" 2> /dev/null); then
    if bool_val=$(parse_bool "$value" 2> /dev/null); then
      INSTALL_DEPS_ENABLED="$bool_val"
    fi
  fi

  if value=$(config_get "add.install-deps.command" 2> /dev/null); then
    INSTALL_DEPS_COMMAND="$value"
  fi

  if value=$(config_get "add.copy-env.enabled" 2> /dev/null); then
    if bool_val=$(parse_bool "$value" 2> /dev/null); then
      COPY_ENV_ENABLED="$bool_val"
    fi
  fi

  if value=$(config_get "add.copy-env.files" 2> /dev/null); then
    if [ -n "$value" ] && [[ "$value" =~ ^\[.*\]$ ]]; then
      local trimmed="${value#[}"
      trimmed="${trimmed%]}"
      local -a files=()
      if [ -n "$trimmed" ]; then
        local -a raw_items=()
        IFS=',' read -r -a raw_items <<< "$trimmed"
        local item=""
        for item in "${raw_items[@]}"; do
          item="${item#"${item%%[![:space:]]*}"}"
          item="${item%"${item##*[![:space:]]}"}"
          item="${item#\"}"
          item="${item%\"}"
          [ -n "$item" ] && files+=("$item")
        done
      fi
      if [ ${#files[@]} -gt 0 ]; then
        COPY_ENV_FILE_SELECTION=("${files[@]}")
      fi
    fi
  fi

  if value=$(config_get "remove.pre-command" 2> /dev/null); then
    REMOVE_PRE_COMMAND="$value"
  fi

  return 0
}

init_settings_defaults() {
  WORKING_REPO_PATH="$CONFIG_DEFAULT_WORKING_REPO_PATH"
  SERVE_DEV_LOGGING_PATH="$CONFIG_DEFAULT_SERVE_DEV_LOGGING_PATH"
  SERVE_DEV_ENABLED="$CONFIG_DEFAULT_SERVE_DEV_ENABLED"
  SERVE_DEV_READY_TIMEOUT="$CONFIG_DEFAULT_SERVE_DEV_READY_TIMEOUT"
  SERVE_DEV_SETTLE_TIMEOUT="$CONFIG_DEFAULT_SERVE_DEV_SETTLE_TIMEOUT"
  INSTALL_DEPS_ENABLED="$CONFIG_DEFAULT_INSTALL_DEPS_ENABLED"
  COPY_ENV_ENABLED="$CONFIG_DEFAULT_COPY_ENV_ENABLED"
  WORKTREE_BRANCH_PREFIX="$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX"
  COPY_ENV_FILE_SELECTION=("${CONFIG_DEFAULT_COPY_ENV_FILES[@]}")
  INSTALL_DEPS_COMMAND="$CONFIG_DEFAULT_INSTALL_DEPS_COMMAND"
  SERVE_DEV_COMMAND="$CONFIG_DEFAULT_SERVE_DEV_COMMAND"
  ADD_POST_COMMAND="$CONFIG_DEFAULT_ADD_POST_COMMAND"
  REMOVE_PRE_COMMAND="$CONFIG_DEFAULT_REMOVE_PRE_COMMAND"
  WORKING_REPO_PATH_CONFIGURED=0
  LANGUAGE="$CONFIG_DEFAULT_LANGUAGE"
  LIST_THEME="$CONFIG_DEFAULT_THEME"

  WORKTREE_NAME_PREFIX="$(basename "$CONFIG_DEFAULT_WORKING_REPO_PATH")."

  init_language
  init_theme
}

config_bool_to_string() {
  if [ "$1" -eq 1 ]; then
    printf 'true\n'
  else
    printf 'false\n'
  fi
}

info() {
  printf '%s\n' "$*" >&2
}

die() {
  prompt_show_cursor
  printf 'wt: %s\n' "$*" >&2
  exit 1
}

usage() {
  local project_dir_box_display="$WORKING_REPO_PATH"
  local dir_text_en
  local dir_text_zh
  local should_highlight=0

  if [ "$WORKING_REPO_PATH_CONFIGURED" -eq 1 ]; then
    dir_text_en="Project directory: ${project_dir_box_display}"
    dir_text_zh="${dir_text_en}"
    should_highlight=1
  else
    dir_text_en="Project directory: not set; run wt init inside your repo"
    dir_text_zh="${dir_text_en}"
  fi

  local banner_width_en=${#dir_text_en}
  local banner_width_zh=${#dir_text_zh}

  if [ "$banner_width_en" -lt 40 ]; then
    banner_width_en=40
  fi
  if [ "$banner_width_zh" -lt 40 ]; then
    banner_width_zh=40
  fi

  local fill_en fill_zh
  fill_en=$(printf '%*s' "$banner_width_en" '')
  fill_en=${fill_en// /─}
  fill_zh=$(printf '%*s' "$banner_width_zh" '')
  fill_zh=${fill_zh// /─}

  local dir_top_en dir_mid_en dir_bottom_en dir_top_zh dir_mid_zh dir_bottom_zh
  dir_top_en="${fill_en}╮"
  dir_mid_en=$(printf '%-*s│' "$banner_width_en" "$dir_text_en")
  dir_bottom_en="${fill_en}╯"

  dir_top_zh="${fill_zh}╮"
  dir_mid_zh=$(printf '%-*s│' "$banner_width_zh" "$dir_text_zh")
  dir_bottom_zh="${fill_zh}╯"

  local dir_mid_en_line="$dir_mid_en"
  local dir_mid_zh_line="$dir_mid_zh"
  if [ "$should_highlight" -eq 1 ] && [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
    dir_mid_en_line="$(format_cyan_bold_line "$dir_mid_en")"
    dir_mid_zh_line="$(format_cyan_bold_line "$dir_mid_zh")"
  fi

  local dir_mid_en_line="$dir_mid_en"
  local dir_mid_zh_line="$dir_mid_zh"
  if [ "$should_highlight" -eq 1 ] && [ -z "${NO_COLOR:-}" ] && { [ -t 1 ] || [ -t 2 ]; }; then
    local path_highlight
    path_highlight=$(format_cyan_bold_line "$project_dir_box_display")
    dir_mid_en_line=${dir_mid_en_line//Project directory: $project_dir_box_display/Project directory: $path_highlight}
    dir_mid_zh_line=${dir_mid_zh_line//Project directory: $project_dir_box_display/Project directory: $path_highlight}
  fi

  local dir_banner_en dir_banner_zh
  dir_banner_en=$(printf '%s\n%s\n%s' "$dir_top_en" "$dir_mid_en_line" "$dir_bottom_en")
  dir_banner_zh=$(printf '%s\n%s\n%s' "$dir_top_zh" "$dir_mid_zh_line" "$dir_bottom_zh")

  case "$LANGUAGE" in
  zh)
    cat << USAGE_ZH

用法:
  wt <command> [参数]        执行 wt 子命令
  wt <worktree-name>         直接跳转到对应 worktree

核心命令:
  init               将当前仓库设为 wt 的默认项目
  add <name>         创建新 worktree；名称为纯数字或以数字结尾时会自动推断 dev 端口
  main               跳转到主 worktree
  merge <name>       将指定 worktree 的分支（feat/<name>）合并到主分支
  sync [all|name ...] 将主工作区的暂存改动同步到其他 worktree
  list               列出所有 worktree
  rm [name ...]      删除一个或多个 worktree（省略 name 时使用当前目录）
  clean              清理数字 worktree（匹配前缀 + 数字）
  config             查看或更新 worktree.sh 配置
  lang               切换 CLI 语言（交互式或使用 wt lang set/get/reset）
  theme             切换列表主题（交互式或使用 wt theme set/get/reset）
  uninstall          卸载 wt 并清理 shell 集成
  reinstall          运行 uninstall.sh + install.sh 重新部署 wt
  help               显示此帮助

帮助:
  wt help <command>  查看子命令帮助
  wt <command> --help 与上面等价，例如 wt add --help

${dir_banner_zh}

USAGE_ZH
    ;;
  *)
    cat << USAGE_EN

Usage:
  wt <command> [args]        Run a wt subcommand
  wt <worktree-name>         Jump straight to a worktree

Core commands:
  init               Remember this repository as wt's default project
  add <name>         Create a new worktree; numeric names or trailing digits also infer the dev port
  main               Jump to the main worktree
  merge <name>       Merge the feature branch (feat/<name>) back into the base branch
  sync [all|name ...] Sync staged changes from the main workspace into other worktrees
  list               List all worktrees
  rm [name ...]      Remove one or more worktrees (current directory if name omitted)
  clean              Remove numeric worktrees (matching prefix + digits)
  config             Inspect or update worktree.sh configuration
  lang               Switch CLI language (interactive or via wt lang set/get/reset)
  theme             Switch list theme (interactive or via wt theme set/get/reset)
  uninstall          Uninstall wt and clean shell hooks
  reinstall          Run uninstall.sh + install.sh to refresh wt
  help               Show this guide

Help:
  wt help <command>  Show subcommand help
  wt <command> --help Same as above, for example wt add --help

${dir_banner_en}

USAGE_EN
    ;;
  esac
}

usage_exit() {
  local status="${1:-0}"
  usage
  exit "$status"
}

PROJECT_DIR=""
PROJECT_DIR_ABS=""
PROJECT_PARENT=""

resolve_project() {
  command -v git > /dev/null 2>&1 || die "$(msg git_required)"

  if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -ne 1 ] && [ "$PROJECT_CONFIG_EXISTS" -ne 1 ]; then
    die "$(msg project_dir_unset)"
  fi

  if [ -z "$WORKING_REPO_PATH" ]; then
    die "$(msg project_dir_unset)"
  fi

  PROJECT_DIR="$WORKING_REPO_PATH"

  # Use canonical path to avoid case-only mismatches on case-insensitive FS.
  if ! PROJECT_DIR_ABS=$(canonical_path "$PROJECT_DIR" 2> /dev/null); then
    if [ -n "$PROJECT_DETECTED_ROOT" ]; then
      PROJECT_DIR_ABS="$PROJECT_DETECTED_ROOT"
      PROJECT_DIR="$PROJECT_DIR_ABS"
    else
      die "$(msg project_not_found "$PROJECT_DIR")"
    fi
  fi

  PROJECT_PARENT=$(dirname "$PROJECT_DIR_ABS")
}

worktree_path_for() {
  local name="$1"
  printf '%s/%s%s\n' "$PROJECT_PARENT" "$WORKTREE_NAME_PREFIX" "$name"
}

worktree_ref_exists() {
  local target="$1"
  local line

  while IFS= read -r line; do
    case "$line" in
    worktree\ *)
      local candidate="${line#worktree }"
      if [ "$candidate" = "$target" ]; then
        return 0
      fi
      ;;
    esac
  done < <(git_project worktree list --porcelain)

  return 1
}

path_is_within() {
  if [ $# -ne 2 ]; then
    return 1
  fi

  local path="$1"
  local root="$2"

  case "$path" in
  "$root" | "$root"/*)
    return 0
    ;;
  esac

  return 1
}

ensure_within_project_directory() {
  if [ -z "$PROJECT_DIR_ABS" ]; then
    return 1
  fi

  local current_dir
  if ! current_dir=$(pwd -P 2> /dev/null); then
    return 1
  fi

  if path_is_within "$current_dir" "$PROJECT_DIR_ABS"; then
    return 0
  fi

  local git_toplevel=""
  git_toplevel=$(git rev-parse --show-toplevel 2> /dev/null || true)
  if [ -n "$git_toplevel" ]; then
    if git_toplevel=$(cd "$git_toplevel" 2> /dev/null && pwd -P); then
      if [ "$git_toplevel" = "$PROJECT_DIR_ABS" ]; then
        return 0
      fi

      # Accept commands executed from registered worktree roots.
      if worktree_branch_for_path "$git_toplevel" > /dev/null 2>&1; then
        return 0
      fi
    fi
  fi

  die "$(msg project_directory_required "$PROJECT_DIR_ABS")"
}

project_current_branch() {
  local branch
  branch=$(git_project symbolic-ref --quiet --short HEAD 2> /dev/null || true)
  if [ -n "$branch" ]; then
    printf '%s\n' "$branch"
    return 0
  fi

  return 1
}

branch_prefix_conflict() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local prefix="$1"
  local base="${prefix%/}"

  if [ -z "$base" ]; then
    printf 'invalid\n'
    return 0
  fi

  if git_project show-ref --verify --quiet "refs/heads/$base"; then
    printf '%s\n' "$base"
    return 0
  fi

  return 1
}

ensure_branch_prefix_for_add() {
  local original
  original="$(normalize_branch_prefix_value "$WORKTREE_BRANCH_PREFIX")"
  if [ -z "$original" ]; then
    original="$CONFIG_DEFAULT_WORKTREE_ADD_BRANCH_PREFIX"
  fi

  local -a candidates=("$original")
  local fallback=""
  for fallback in "${CONFIG_BRANCH_PREFIX_FALLBACKS[@]}"; do
    fallback="$(normalize_branch_prefix_value "$fallback")"
    if [ -z "$fallback" ]; then
      continue
    fi
    local duplicate=0
    local existing=""
    for existing in "${candidates[@]}"; do
      if [ "$existing" = "$fallback" ]; then
        duplicate=1
        break
      fi
    done
    if [ "$duplicate" -eq 0 ]; then
      candidates+=("$fallback")
    fi
  done

  local candidate=""
  local conflict_reason=""
  local conflict_hint=""
  for candidate in "${candidates[@]}"; do
    if conflict_reason=$(branch_prefix_conflict "$candidate" 2> /dev/null); then
      if [ "$conflict_reason" != 'invalid' ]; then
        conflict_hint="$conflict_reason"
      fi
      continue
    fi

    WORKTREE_BRANCH_PREFIX="$candidate"
    if [ "$candidate" != "$original" ]; then
      local message_hint="$conflict_hint"
      if [ -z "$message_hint" ]; then
        message_hint="${original%/}"
        if [ -z "$message_hint" ]; then
          message_hint='(empty)'
        fi
      fi
      info "$(msg add_branch_prefix_fallback "$message_hint" "$candidate" "$candidate")"
    fi
    return 0
  done

  local failed_prefix="${original%/}"
  if [ -z "$failed_prefix" ]; then
    failed_prefix='(empty)'
  fi
  die "$(msg add_branch_prefix_exhausted "$failed_prefix")"
}

worktree_branch_for_path_in_repo() {
  if [ $# -ne 2 ]; then
    return 1
  fi

  local repo_path="$1"
  local lookup_path="$2"

  if [ -z "$repo_path" ] || [ -z "$lookup_path" ]; then
    return 1
  fi

  local list_output=""
  if ! list_output=$(git_at_path "$repo_path" worktree list --porcelain 2> /dev/null); then
    return 1
  fi

  local line=""
  local current_path=""
  local current_branch=""
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
    worktree\ *)
      if [ -n "$current_path" ] && [ "$current_path" = "$lookup_path" ] && [ -n "$current_branch" ]; then
        printf '%s\n' "$current_branch"
        return 0
      fi
      current_path="${line#worktree }"
      current_branch=""
      ;;
    branch\ *)
      current_branch="${line#branch }"
      current_branch="${current_branch#refs/heads/}"
      ;;
    "")
      if [ -n "$current_path" ] && [ "$current_path" = "$lookup_path" ] && [ -n "$current_branch" ]; then
        printf '%s\n' "$current_branch"
        return 0
      fi
      current_path=""
      current_branch=""
      ;;
    esac
  done <<< "$list_output"

  if [ -n "$current_path" ] && [ "$current_path" = "$lookup_path" ] && [ -n "$current_branch" ]; then
    printf '%s\n' "$current_branch"
    return 0
  fi

  return 1
}

worktree_branch_for_path() {
  if [ $# -ne 1 ]; then
    return 1
  fi

  local lookup_path="$1"
  if [ -z "$lookup_path" ]; then
    return 1
  fi

  worktree_branch_for_path_in_repo "$PROJECT_DIR_ABS" "$lookup_path"
}

protected_worktree_branch() {
  case "${1:-}" in
  main | master | develop | dev)
    return 0
    ;;
  esac

  return 1
}

expected_worktree_branch_name() {
  if [ $# -lt 1 ]; then
    return 1
  fi

  local name="$1"
  local branch_prefix="${2:-}"

  if [ -n "$branch_prefix" ]; then
    printf '%s%s\n' "$branch_prefix" "$name"
  else
    printf '%s\n' "$name"
  fi
}

WT_VALIDATED_REMOVE_BRANCH=""
WT_REMOVE_BRANCH_REASON=""
WT_REMOVE_BRANCH_EXPECTED=""

validate_removable_worktree_branch() {
  if [ $# -lt 2 ]; then
    return 1
  fi

  local name="$1"
  local actual_branch="$2"
  local branch_prefix="${3:-}"

  WT_VALIDATED_REMOVE_BRANCH=""
  WT_REMOVE_BRANCH_REASON=""
  WT_REMOVE_BRANCH_EXPECTED=""
  WT_REMOVE_BRANCH_EXPECTED=$(expected_worktree_branch_name "$name" "$branch_prefix")

  if [ -z "$actual_branch" ]; then
    WT_REMOVE_BRANCH_REASON='missing'
    return 1
  fi

  if protected_worktree_branch "$actual_branch"; then
    WT_REMOVE_BRANCH_REASON='protected'
    return 1
  fi

  if [ -n "$WT_REMOVE_BRANCH_EXPECTED" ] && [ "$actual_branch" != "$WT_REMOVE_BRANCH_EXPECTED" ]; then
    WT_REMOVE_BRANCH_REASON='mismatch'
    return 1
  fi

  WT_VALIDATED_REMOVE_BRANCH="$actual_branch"
  return 0
}

log_skipped_branch_removal() {
  if [ $# -lt 1 ]; then
    return 1
  fi

  local target_path="$1"
  local actual_branch="${2:-}"
  local expected_branch="${3:-$WT_REMOVE_BRANCH_EXPECTED}"
  local reason="${4:-$WT_REMOVE_BRANCH_REASON}"

  case "$reason" in
  protected)
    info "$(msg remove_branch_skip_protected "$target_path" "$actual_branch" "$expected_branch")"
    ;;
  mismatch)
    info "$(msg remove_branch_skip_mismatch "$target_path" "$actual_branch" "$expected_branch")"
    ;;
  missing)
    info "$(msg remove_branch_skip_missing "$target_path" "$expected_branch")"
    ;;
  esac
}

branch_for() {
  local name="$1"
  local target_path
  target_path=$(worktree_path_for "$name")

  local branch=""
  if branch=$(worktree_branch_for_path "$target_path" 2> /dev/null); then
    if [ -n "$branch" ]; then
      printf '%s\n' "$branch"
      return 0
    fi
  fi

  printf '%s%s\n' "$WORKTREE_BRANCH_PREFIX" "$name"
}

detect_repo_default_branch() {
  local remote_head
  remote_head=$(git_project symbolic-ref --quiet --short refs/remotes/origin/HEAD 2> /dev/null || true)
  if [ -n "$remote_head" ]; then
    remote_head=${remote_head#origin/}
    if [ -n "$remote_head" ]; then
      printf '%s\n' "$remote_head"
      return 0
    fi
  fi

  local candidate
  for candidate in main master; do
    if git_project show-ref --verify --quiet "refs/heads/$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if [ -n "${1:-}" ]; then
    printf '%s\n' "$1"
  fi
}

validate_worktree_name() {
  local candidate="${1:-}"

  if [ -z "$candidate" ]; then
    return 1
  fi

  if [[ "$candidate" =~ [[:space:]] ]]; then
    return 1
  fi

  case "$candidate" in
  . | '..' | */* | *\\* | *~*)
    return 1
    ;;
  esac

  return 0
}

port_from_name() {
  local name="$1"
  local digits=""

  if [[ "$name" =~ ^([0-9]+)$ ]]; then
    digits="${BASH_REMATCH[1]}"
  elif [[ "$name" =~ ([0-9]+)$ ]]; then
    digits="${BASH_REMATCH[1]}"
  fi

  if [ -n "$digits" ]; then
    if [ "$digits" -ge 1024 ] && [ "$digits" -le 65535 ]; then
      printf '%s\n' "$digits"
      return 0
    fi
  fi

  printf ''
}

git_project() {
  git -C "$PROJECT_DIR_ABS" "$@"
}

git_at_path() {
  if [ $# -lt 2 ]; then
    return 1
  fi

  local repo_path="$1"
  shift
  git -C "$repo_path" "$@"
}

copy_env_file() {
  local entry="$1"
  local target_dir="$2"
  local source_rel="$entry"
  local dest_rel=""

  if [[ "$entry" == *:* ]]; then
    source_rel="${entry%%:*}"
    dest_rel="${entry#*:}"
  fi

  if [ -z "$dest_rel" ]; then
    dest_rel="$source_rel"
  fi

  local source_path="$PROJECT_DIR_ABS/$source_rel"
  local dest_path="$target_dir/$dest_rel"

  if [ -d "$source_path" ]; then
    mkdir -p "$dest_path"
    if command -v rsync > /dev/null 2>&1; then
      rsync -a "$source_path/" "$dest_path/"
    else
      cp -R "$source_path"/. "$dest_path/"
    fi
    info "$(msg copy_env_file "$source_rel" "$dest_rel")"
    return
  fi

  if [ -f "$source_path" ]; then
    local dest_dir
    dest_dir=$(dirname "$dest_path")
    mkdir -p "$dest_dir"
    dest_path=${dest_path%/}
    cp "$source_path" "$dest_path"
    info "$(msg copy_env_file "$source_rel" "$dest_rel")"
    return
  fi

  info "$(msg copy_env_missing "$source_rel")"
}

command_exists_for_line() {
  local line="$1"
  if [ -z "$line" ]; then
    return 1
  fi

  local -a tokens
  IFS=' ' read -r -a tokens <<< "$line"
  if [ ${#tokens[@]} -eq 0 ]; then
    return 1
  fi

  local token
  for token in "${tokens[@]}"; do
    if [[ "$token" == *=* ]]; then
      continue
    fi
    if command -v "$token" > /dev/null 2>&1; then
      return 0
    fi
    return 1
  done

  return 1
}

port_is_listening() {
  local port="${1:-}"
  if [ -z "$port" ]; then
    return 1
  fi

  case "$port" in
  *[!0-9]*)
    return 1
    ;;
  esac

  if command -v lsof > /dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN > /dev/null 2>&1
    return $?
  fi

  (exec 3<> "/dev/tcp/127.0.0.1/$port") > /dev/null 2>&1
}

wait_for_dev_port() {
  local port="${1:?port is required}"
  local timeout_sec="${2:-60}"
  local pid="${3:-}"
  local exit_grace_sec="${4:-2}"
  local waited=0
  local dead_wait=0

  while [ "$waited" -lt "$timeout_sec" ]; do
    if port_is_listening "$port"; then
      return 0
    fi

    if [ -n "$pid" ] && ! kill -0 "$pid" 2> /dev/null; then
      dead_wait=$((dead_wait + 1))
      if [ "$dead_wait" -ge "$exit_grace_sec" ]; then
        return 1
      fi
    else
      dead_wait=0
    fi

    sleep 1
    waited=$((waited + 1))
  done

  return 2
}

wait_for_dev_settle() {
  local port="${1:?port is required}"
  local pid="${2:-}"
  local timeout_sec="${3:-5}"
  local waited=0

  if [ -z "$pid" ]; then
    return 0
  fi

  while [ "$waited" -lt "$timeout_sec" ]; do
    if ! kill -0 "$pid" 2> /dev/null; then
      return 0
    fi

    if ! port_is_listening "$port"; then
      return 1
    fi

    sleep 1
    waited=$((waited + 1))
  done

  return 0
}

node_lockfile_present() {
  local worktree_path="${1:?worktree path is required}"
  if [ -f "$worktree_path/package-lock.json" ] || [ -f "$worktree_path/npm-shrinkwrap.json" ]; then
    return 0
  fi
  return 1
}

run_install_command() {
  local worktree_path="${1:?worktree path is required}"
  local command_line="${2:-}"

  if [ -z "$command_line" ]; then
    info "$(msg install_skipped_no_command)"
    return
  fi

  if ! command_exists_for_line "$command_line"; then
    info "$(msg command_not_found "$command_line")"
    return
  fi

  local complex_command=0
  case "$command_line" in
  *'&&'* | *'||'* | *';'* | *'|'*)
    complex_command=1
    ;;
  esac

  if [ "$complex_command" -eq 0 ]; then
    local -a tokens=()
    local token=""
    IFS=' ' read -r -a tokens <<< "$command_line"
    local -a filtered=()
    for token in "${tokens[@]}"; do
      if [[ "$token" == *=* ]]; then
        continue
      fi
      filtered+=("$token")
    done

    if [ ${#filtered[@]} -gt 0 ]; then
      local primary="${filtered[0]}"
      local subcommand=""
      if [ ${#filtered[@]} -ge 2 ]; then
        subcommand="${filtered[1]}"
      fi

      if [ "$primary" = "npm" ]; then
        case "$subcommand" in
        ci | install)
          if ! node_lockfile_present "$worktree_path"; then
            info "$(msg install_skipped_missing_lock "$command_line")"
            return
          fi
          ;;
        esac
      fi
    fi
  fi

  info "$(msg installing_dependencies "$command_line")"
  (
    cd "$worktree_path" || exit
    sh -c "$command_line" >&2
  )
}

run_configured_hook_command() {
  local command_line="${1:-}"
  local cwd="${2:-}"
  local phase="${3:-hook}"
  local worktree_name="${4:-}"
  local worktree_path="${5:-}"
  local worktree_branch="${6:-}"

  if [ -z "$command_line" ]; then
    return 0
  fi

  if ! command_exists_for_line "$command_line"; then
    info "⚠️  $phase hook command not found: $command_line"
    return 1
  fi

  if [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
    info "⚠️  $phase hook working directory missing: $cwd"
    return 1
  fi

  info "⚙️  Running $phase hook: $command_line"

  (
    cd "$cwd" || exit 1
    env \
      WT_HOOK_PHASE="$phase" \
      WT_PROJECT_ROOT="$PROJECT_DIR_ABS" \
      WT_WORKTREE_NAME="$worktree_name" \
      WT_WORKTREE_PATH="$worktree_path" \
      WT_WORKTREE_BRANCH="$worktree_branch" \
      sh -c "$command_line"
  )
}

command_slug_from_line() {
  local line="$1"
  if [ -z "$line" ]; then
    printf 'dev'
    return
  fi

  local slug
  slug=$(printf '%s' "$line" | tr "[:space:]/\\" '_')
  slug=${slug//[^A-Za-z0-9._-]/_}
  slug=${slug#_}
  slug=${slug%%_}
  if [ -z "$slug" ]; then
    slug='dev'
  fi
  slug=${slug:0:40}
  printf '%s' "$slug"
}

# Python 工具检测 - 使用严格的判据避免误判
detect_python_tool() {
  local project_path="${1:?project path required}"

  # uv - 需要 uv.lock 或 pyproject.toml 中的 [tool.uv]
  if [ -f "$project_path/uv.lock" ]; then
    echo "uv"
    return 0
  fi
  if [ -f "$project_path/pyproject.toml" ] && grep -Eq '^[[:space:]]*\[tool\.uv\]' "$project_path/pyproject.toml" 2> /dev/null; then
    echo "uv"
    return 0
  fi

  # rye - 需要 rye 特定文件
  if [ -f "$project_path/rye.lock" ] || [ -f "$project_path/.rye/config.toml" ]; then
    echo "rye"
    return 0
  fi

  # poetry - 需要 poetry.lock 或 pyproject.toml 中的 [tool.poetry]
  if [ -f "$project_path/poetry.lock" ]; then
    echo "poetry"
    return 0
  fi
  if [ -f "$project_path/pyproject.toml" ] && grep -Eq '^[[:space:]]*\[tool\.poetry\]' "$project_path/pyproject.toml" 2> /dev/null; then
    echo "poetry"
    return 0
  fi

  # pdm - 需要 pdm 特定文件
  if [ -f "$project_path/pdm.lock" ] || [ -f "$project_path/.pdm.toml" ]; then
    echo "pdm"
    return 0
  fi
  if [ -f "$project_path/pyproject.toml" ] && grep -Eq '^[[:space:]]*\[tool\.pdm\]' "$project_path/pyproject.toml" 2> /dev/null; then
    echo "pdm"
    return 0
  fi

  # pipenv - 需要 Pipfile 或 Pipfile.lock
  if [ -f "$project_path/Pipfile.lock" ] || [ -f "$project_path/Pipfile" ]; then
    echo "pipenv"
    return 0
  fi

  # hatch - 需要 hatch.toml 或 pyproject.toml 中的 [tool.hatch]
  if [ -f "$project_path/hatch.toml" ]; then
    echo "hatch"
    return 0
  fi
  if [ -f "$project_path/pyproject.toml" ] && grep -Eq '^[[:space:]]*\[tool\.hatch\]' "$project_path/pyproject.toml" 2> /dev/null; then
    echo "hatch"
    return 0
  fi

  # conda - 需要环境定义文件或已创建的 conda 环境目录
  if find_conda_env_file "$project_path" > /dev/null; then
    echo "conda"
    return 0
  fi
  if [ -d "$project_path/conda-meta" ]; then
    echo "conda"
    return 0
  fi
  local conda_prefix
  for conda_prefix in ".conda" "env" "venv" ".venv"; do
    if [ -d "$project_path/$conda_prefix/conda-meta" ]; then
      echo "conda"
      return 0
    fi
  done

  # pip - 作为默认回退，但需要有 Python 项目标志文件
  if [ -f "$project_path/requirements.txt" ] || [ -f "$project_path/setup.py" ] || [ -f "$project_path/setup.cfg" ]; then
    echo "pip"
    return 0
  fi
  # pyproject.toml 但没有特定工具配置时也使用 pip
  if [ -f "$project_path/pyproject.toml" ]; then
    echo "pip"
    return 0
  fi

  return 1
}

# Python 框架检测 - 优化文件检测逻辑
detect_python_framework() {
  local project_path="${1:?project path required}"

  # Django - 检测 manage.py
  if [ -f "$project_path/manage.py" ]; then
    echo "django"
    return 0
  fi

  # FastAPI - 检查根目录和常见子目录
  local fastapi_locations=("main.py" "app.py" "app/main.py" "src/main.py" "api/main.py" "app/app.py" "src/app.py")
  local location
  for location in "${fastapi_locations[@]}"; do
    if [ -f "$project_path/$location" ]; then
      if grep -qi "fastapi" "$project_path/$location" 2> /dev/null; then
        echo "fastapi"
        return 0
      fi
    fi
  done

  # Flask - 检查根目录和常见子目录
  local flask_locations=("app.py" "application.py" "app/app.py" "src/app.py" "app/application.py" "src/application.py")
  for location in "${flask_locations[@]}"; do
    if [ -f "$project_path/$location" ]; then
      if grep -qi "flask" "$project_path/$location" 2> /dev/null; then
        echo "flask"
        return 0
      fi
    fi
  done

  # Streamlit - 更高效的文件检测
  local py_file
  for py_file in "$project_path"/*.py; do
    if [ -f "$py_file" ]; then
      if grep -qi "streamlit" "$py_file" 2> /dev/null; then
        echo "streamlit"
        return 0
      fi
    fi
  done

  # Jupyter - 简单检查 .ipynb 文件存在
  local nb_file
  for nb_file in "$project_path"/*.ipynb; do
    if [ -f "$nb_file" ]; then
      echo "jupyter"
      return 0
    fi
  done

  # 通用 Python 应用
  if [ -f "$project_path/app.py" ] || [ -f "$project_path/main.py" ]; then
    echo "python"
    return 0
  fi

  return 1
}

# 检测 Python 虚拟环境
detect_python_venv() {
  local project_path="${1:?project path required}"

  # 常见的虚拟环境目录
  for venv in ".venv" "venv" "env" ".env"; do
    if [ -d "$project_path/$venv" ] && [ -f "$project_path/$venv/bin/python" ]; then
      echo "$venv"
      return 0
    fi
  done

  return 1
}

find_conda_env_file() {
  local project_path="${1:?project path required}"
  local candidates=(
    "environment.yml"
    "environment.yaml"
    "environment.lock.yml"
    "environment.lock.yaml"
    "conda.yml"
    "conda.yaml"
    "conda-lock.yml"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [ -f "$project_path/$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

detect_conda_env_name() {
  local project_path="${1:?project path required}"
  local env_file

  if ! env_file=$(find_conda_env_file "$project_path"); then
    return 1
  fi

  local name_line
  name_line=$(grep -E '^[[:space:]]*name:' "$project_path/$env_file" | head -n 1)
  if [ -z "$name_line" ]; then
    return 1
  fi

  name_line=${name_line#*:}
  name_line=$(printf '%s\n' "$name_line" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*(#.*)?$//')
  # 去除包裹的引号
  name_line=${name_line%\"}
  name_line=${name_line#\"}
  name_line=${name_line%\'}
  name_line=${name_line#\'}

  if [ -n "$name_line" ]; then
    printf '%s\n' "$name_line"
    return 0
  fi

  return 1
}

detect_conda_env_prefix() {
  local project_path="${1:?project path required}"
  local env_file

  if env_file=$(find_conda_env_file "$project_path"); then
    local prefix_line
    prefix_line=$(grep -E '^[[:space:]]*prefix:' "$project_path/$env_file" | head -n 1)
    if [ -n "$prefix_line" ]; then
      prefix_line=${prefix_line#*:}
      prefix_line=$(printf '%s\n' "$prefix_line" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*(#.*)?$//')
      prefix_line=${prefix_line%\"}
      prefix_line=${prefix_line#\"}
      prefix_line=${prefix_line%\'}
      prefix_line=${prefix_line#\'}
      if [ -n "$prefix_line" ]; then
        printf '%s\n' "$prefix_line"
        return 0
      fi
    fi
  fi

  # 检查常见的项目内 conda 环境目录
  if [ -d "$project_path/conda-meta" ]; then
    printf '%s\n' "$project_path"
    return 0
  fi

  local candidate
  for candidate in ".conda" "env" "venv" ".venv"; do
    if [ -d "$project_path/$candidate/conda-meta" ]; then
      printf '%s\n' "$project_path/$candidate"
      return 0
    fi
  done

  return 1
}

# 查找 Python 应用入口文件
# 返回相对于项目根目录的路径，用于生成正确的 uvicorn 命令
find_python_app_entry() {
  local project_path="${1:?project path required}"
  local framework="${2:-}"

  case "$framework" in
  fastapi)
    # FastAPI 常见位置
    local locations=("main.py" "app.py" "app/main.py" "src/main.py" "api/main.py" "app/app.py" "src/app.py")
    local location
    for location in "${locations[@]}"; do
      if [ -f "$project_path/$location" ]; then
        if grep -qi "fastapi" "$project_path/$location" 2> /dev/null; then
          echo "$location"
          return 0
        fi
      fi
    done
    ;;
  flask)
    # Flask 常见位置
    local locations=("app.py" "application.py" "app/app.py" "src/app.py")
    for location in "${locations[@]}"; do
      if [ -f "$project_path/$location" ]; then
        if grep -qi "flask" "$project_path/$location" 2> /dev/null; then
          echo "$location"
          return 0
        fi
      fi
    done
    ;;
  *)
    # 通用 Python 应用
    if [ -f "$project_path/main.py" ]; then
      echo "main.py"
      return 0
    elif [ -f "$project_path/app.py" ]; then
      echo "app.py"
      return 0
    elif [ -f "$project_path/app/main.py" ]; then
      echo "app/main.py"
      return 0
    elif [ -f "$project_path/src/main.py" ]; then
      echo "src/main.py"
      return 0
    fi
    ;;
  esac

  return 1
}

# 辅助函数：为传统虚拟环境生成命令
# 确保命令能在 sh -c 下正确解析，正确处理包含空格的路径
wrap_venv_command() {
  local venv_path="${1:?venv path required}"
  local command="${2:?command required}"

  # 检查命令类型，决定如何包装
  case "$command" in
  python*)
    # Python 命令：使用虚拟环境中的 python，正确引用路径
    # 替换第一个 python 为虚拟环境路径（引用以处理空格）
    local rest="${command#python}"
    echo "\"${venv_path}/bin/python\"${rest}"
    ;;
  flask* | streamlit* | uvicorn* | jupyter* | pip*)
    # 这些工具：使用虚拟环境中的版本
    local tool="${command%% *}"
    local args="${command#* }"
    if [ "$tool" = "$command" ]; then
      # 没有参数
      echo "\"${venv_path}/bin/${tool}\""
    else
      # 有参数
      echo "\"${venv_path}/bin/${tool}\" $args"
    fi
    ;;
  *)
    # 其他命令：保持原样
    echo "$command"
    ;;
  esac
}

# 辅助函数：生成激活虚拟环境并执行命令的字符串
# 用于需要 source 激活的场景（如安装命令）
# 使用 POSIX 兼容的 . 命令而不是 source，确保在 sh -c 下能正确执行
venv_activate_and_run() {
  local venv_path="${1:?venv path required}"
  local command="${2:?command required}"

  # 使用 . 而不是 source（POSIX 兼容），并正确引用路径以处理空格
  echo ". \"${venv_path}/bin/activate\" && $command"
}

# 生成 Python 服务命令（包含虚拟环境处理）
generate_python_serve_cmd() {
  local project_path="${1:?project path required}"
  local tool="${2:?tool required}"
  local framework="${3:?framework required}"
  local venv_path="${4:-}"

  # 基础命令
  local base_cmd=""
  case "$framework" in
  django)
    base_cmd="python manage.py runserver"
    ;;
  fastapi)
    # 查找 FastAPI 应用入口文件
    local app_entry
    if app_entry=$(find_python_app_entry "$project_path" "fastapi"); then
      # 转换文件路径为模块路径（例如 app/main.py -> app.main:app）
      local module_path="${app_entry%.py}" # 移除 .py 后缀
      module_path="${module_path//\//.}"   # 替换 / 为 .
      base_cmd="uvicorn ${module_path}:app --reload"
    else
      # 默认尝试常见的位置
      base_cmd="uvicorn main:app --reload"
    fi
    ;;
  flask)
    base_cmd="flask run --debug"
    ;;
  streamlit)
    for file in app.py main.py streamlit_app.py; do
      if [ -f "$project_path/$file" ]; then
        base_cmd="streamlit run $file"
        break
      fi
    done
    ;;
  jupyter)
    base_cmd="jupyter lab"
    ;;
  *)
    # 通用 Python 脚本
    local app_entry
    if app_entry=$(find_python_app_entry "$project_path" ""); then
      base_cmd="python $app_entry"
    fi
    ;;
  esac

  # 根据工具添加虚拟环境处理
  case "$tool" in
  uv)
    echo "uv run $base_cmd"
    ;;
  rye)
    echo "rye run $base_cmd"
    ;;
  conda)
    local run_cmd="conda run --live-stream"
    local env_name
    local env_prefix
    if env_name=$(detect_conda_env_name "$project_path"); then
      run_cmd="$run_cmd -n \"$env_name\""
    else
      if env_prefix=$(detect_conda_env_prefix "$project_path"); then
        run_cmd="$run_cmd --prefix \"$env_prefix\""
      fi
    fi

    if [ -n "$base_cmd" ]; then
      echo "$run_cmd $base_cmd"
    else
      echo "$run_cmd"
    fi
    ;;
  poetry)
    echo "poetry run $base_cmd"
    ;;
  pdm)
    echo "pdm run $base_cmd"
    ;;
  pipenv)
    echo "pipenv run $base_cmd"
    ;;
  hatch)
    echo "hatch run $base_cmd"
    ;;
  pip)
    # 使用传统虚拟环境
    if [ -n "$venv_path" ]; then
      wrap_venv_command "$venv_path" "$base_cmd"
    else
      # 如果没有虚拟环境，返回原始命令
      echo "$base_cmd"
    fi
    ;;
  *)
    echo "$base_cmd"
    ;;
  esac
}

# 生成 Python 安装命令（确保创建并激活虚拟环境）
generate_python_install_cmd() {
  local project_path="${1:?project path required}"
  local tool="${2:?tool required}"
  local has_venv="${3:-0}"

  case "$tool" in
  uv)
    if [ "$has_venv" -eq 0 ]; then
      # uv 会自动创建和使用 .venv
      echo "uv venv && uv sync"
    else
      echo "uv sync"
    fi
    ;;
  rye)
    # rye 自动管理虚拟环境
    echo "rye sync"
    ;;
  conda)
    local env_file
    if env_file=$(find_conda_env_file "$project_path"); then
      echo "conda env update --file $env_file --prune || conda env create --file $env_file"
    else
      return 1
    fi
    ;;
  poetry)
    # poetry 自动创建和管理虚拟环境
    if [ -f "$project_path/poetry.lock" ]; then
      echo "poetry install --sync"
    else
      echo "poetry install"
    fi
    ;;
  pdm)
    # pdm 自动管理虚拟环境
    if [ -f "$project_path/pdm.lock" ]; then
      echo "pdm install --frozen-lockfile"
    else
      echo "pdm install"
    fi
    ;;
  pipenv)
    # pipenv 自动管理虚拟环境
    if [ -f "$project_path/Pipfile.lock" ]; then
      echo "pipenv install --deploy"
    else
      echo "pipenv install"
    fi
    ;;
  hatch)
    # hatch 使用自己的环境管理
    echo "hatch env create"
    ;;
  pip)
    # 确定安装命令
    local install_cmd=""
    if [ -f "$project_path/requirements.txt" ]; then
      install_cmd="pip install -r requirements.txt"
    elif [ -f "$project_path/pyproject.toml" ]; then
      install_cmd="pip install -e ."
    fi

    if [ -n "$install_cmd" ]; then
      if [ "$has_venv" -eq 0 ]; then
        # 创建虚拟环境并安装
        echo "python -m venv .venv && $(venv_activate_and_run ".venv" "$install_cmd")"
      else
        # 在现有虚拟环境中安装
        local venv_path
        venv_path=$(detect_python_venv "$project_path")
        venv_activate_and_run "$venv_path" "$install_cmd"
      fi
    fi
    ;;
  esac
}

infer_install_command() {
  local worktree_path="${1:?worktree path is required}"

  if [ -f "$worktree_path/pnpm-lock.yaml" ]; then
    printf 'pnpm install --frozen-lockfile\n'
    return 0
  fi

  if [ -f "$worktree_path/yarn.lock" ]; then
    printf 'yarn install --frozen-lockfile\n'
    return 0
  fi

  if [ -f "$worktree_path/bun.lockb" ]; then
    printf 'bun install\n'
    return 0
  fi

  if [ -f "$worktree_path/package.json" ]; then
    if [ -f "$worktree_path/package-lock.json" ] || [ -f "$worktree_path/npm-shrinkwrap.json" ]; then
      printf 'npm ci\n'
      return 0
    fi
    printf 'npm install\n'
    return 0
  fi

  # Python 项目检测和安装命令生成
  local python_tool
  if python_tool=$(detect_python_tool "$worktree_path"); then
    local has_venv=0
    if detect_python_venv "$worktree_path" > /dev/null; then
      has_venv=1
    fi

    local install_cmd
    if install_cmd=$(generate_python_install_cmd "$worktree_path" "$python_tool" "$has_venv"); then
      printf '%s\n' "$install_cmd"
      return 0
    fi
  fi

  return 1
}

infer_serve_command() {
  local worktree_path="${1:?worktree path is required}"

  if [ -f "$worktree_path/pnpm-lock.yaml" ] && has_package_json_script "$worktree_path" "dev"; then
    printf 'pnpm dev\n'
    return 0
  fi

  if [ -f "$worktree_path/yarn.lock" ] && has_package_json_script "$worktree_path" "dev"; then
    printf 'yarn dev\n'
    return 0
  fi

  if [ -f "$worktree_path/bun.lockb" ] && has_package_json_script "$worktree_path" "dev"; then
    printf 'bun dev\n'
    return 0
  fi

  if [ -f "$worktree_path/package.json" ]; then
    if has_package_json_script "$worktree_path" "dev"; then
      printf 'npm run dev\n'
      return 0
    fi
    if has_package_json_script "$worktree_path" "start"; then
      printf 'npm run start\n'
      return 0
    fi
  fi

  # Python 项目检测和服务命令生成
  local python_tool
  local python_framework
  if python_tool=$(detect_python_tool "$worktree_path"); then
    if python_framework=$(detect_python_framework "$worktree_path"); then
      local venv_path=""
      if detect_python_venv "$worktree_path" > /dev/null; then
        venv_path="$worktree_path/$(detect_python_venv "$worktree_path")"
      fi

      local serve_cmd
      if serve_cmd=$(generate_python_serve_cmd "$worktree_path" "$python_tool" "$python_framework" "$venv_path"); then
        printf '%s\n' "$serve_cmd"
        return 0
      fi
    fi
  fi

  if [ -f "$worktree_path/manage.py" ]; then
    printf 'python manage.py runserver\n'
    return 0
  fi

  local fallback_entry
  if fallback_entry=$(find_python_app_entry "$worktree_path" 2> /dev/null); then
    printf 'python %s\n' "$fallback_entry"
    return 0
  fi

  if [ -f "$worktree_path/app.py" ]; then
    printf 'python app.py\n'
    return 0
  fi

  return 1
}

has_package_json_script() {
  local project_dir="${1:?project directory is required}"
  local script_name="${2:?script name is required}"
  local package_json="$project_dir/package.json"

  [ -f "$package_json" ] || return 1

  if command -v node > /dev/null 2>&1; then
    if node - "$package_json" "$script_name" > /dev/null 2>&1 << 'NODE'; then
const fs = require('fs');
const [pkgPath, scriptName] = process.argv.slice(2);
try {
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8')) || {};
  if (pkg.scripts && pkg.scripts[scriptName]) {
    process.exit(0);
  }
} catch (err) {}
process.exit(1);
NODE
      return 0
    fi
  fi

  local python=""
  for candidate in python3 python; do
    if command -v "$candidate" > /dev/null 2>&1; then
      python="$candidate"
      break
    fi
  done

  if [ -n "$python" ]; then
    if "$python" - "$package_json" "$script_name" > /dev/null 2>&1 << 'PY'; then
import json
import sys

pkg_path = sys.argv[1]
script_name = sys.argv[2]

try:
    with open(pkg_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    scripts = data.get('scripts') or {}
    if scripts.get(script_name):
        sys.exit(0)
except Exception:
    pass

sys.exit(1)
PY
      return 0
    fi
  fi

  return 1
}

start_dev_server() {
  local worktree_path="${1:?worktree path is required}"
  local command_line="${2:-}"
  local port="${3:-}"

  if [ -z "$command_line" ]; then
    info "$(msg dev_skipped_no_command)"
    return
  fi

  if ! command_exists_for_line "$command_line"; then
    info "$(msg command_not_found "$command_line")"
    return
  fi

  mkdir -p "$worktree_path/$SERVE_DEV_LOGGING_PATH"
  local slug
  slug=$(command_slug_from_line "$command_line")

  local log_file
  if [ -n "$port" ]; then
    log_file="$worktree_path/$SERVE_DEV_LOGGING_PATH/${slug}-${port}.log"
  else
    log_file="$worktree_path/$SERVE_DEV_LOGGING_PATH/${slug}.log"
  fi
  local pid_file="${log_file}.pid"

  info "$(msg dev_command "$command_line")"
  if [ -n "$port" ]; then
    info "$(msg start_dev_port "$port")"
  else
    info "$(msg start_dev_generic)"
  fi

  (
    cd "$worktree_path" || exit
    if [ -n "$port" ]; then
      nohup env PORT="$port" sh -c "$command_line" > "$log_file" 2>&1 &
    else
      nohup sh -c "$command_line" > "$log_file" 2>&1 &
    fi
    printf '%s\n' "$!" > "$pid_file"
  )

  local pid=""
  if [ -f "$pid_file" ]; then
    pid=$(cat "$pid_file" 2> /dev/null || true)
  fi

  if [ -n "$port" ]; then
    local ready_timeout="$SERVE_DEV_READY_TIMEOUT"
    local settle_timeout="$SERVE_DEV_SETTLE_TIMEOUT"

    case "$ready_timeout" in
    '' | *[!0-9]*)
      if [ -n "${WT_DEV_READY_TIMEOUT:-}" ] && [[ ! "${WT_DEV_READY_TIMEOUT:-}" =~ [^0-9] ]]; then
        ready_timeout="${WT_DEV_READY_TIMEOUT}"
      else
        ready_timeout="$CONFIG_DEFAULT_SERVE_DEV_READY_TIMEOUT"
      fi
      ;;
    esac
    case "$settle_timeout" in
    '' | *[!0-9]*)
      if [ -n "${WT_DEV_SETTLE_TIMEOUT:-}" ] && [[ ! "${WT_DEV_SETTLE_TIMEOUT:-}" =~ [^0-9] ]]; then
        settle_timeout="${WT_DEV_SETTLE_TIMEOUT}"
      else
        settle_timeout="$CONFIG_DEFAULT_SERVE_DEV_SETTLE_TIMEOUT"
      fi
      ;;
    esac

    if wait_for_dev_port "$port" "$ready_timeout" "$pid"; then
      if ! wait_for_dev_settle "$port" "$pid" "$settle_timeout"; then
        local pid_display="${pid:-unknown}"
        info "$(msg dev_failed "$pid_display" "$log_file")"
      else
        info "$(msg dev_started_port "$port")"
      fi
    else
      local wait_status=$?
      local pid_display="${pid:-unknown}"
      if [ "$wait_status" -eq 1 ]; then
        info "$(msg dev_failed "$pid_display" "$log_file")"
      else
        info "$(msg dev_timeout "$port" "$ready_timeout" "$log_file")"
      fi
    fi
  else
    sleep 1

    if [ -n "$pid" ] && kill -0 "$pid" 2> /dev/null; then
      info "$(msg dev_started_default)"
    else
      local pid_display="${pid:-unknown}"
      info "$(msg dev_failed "$pid_display" "$log_file")"
    fi
  fi

  info "$(msg dev_log_hint "$log_file")"
}

maybe_warn_shell_integration() {
  local target_path="${1:-}"

  if [ -n "${WT_SHELL_WRAPPED:-}" ]; then
    return
  fi

  if [ ! -t 1 ]; then
    return
  fi

  if [ -z "$target_path" ] || [ ! -d "$target_path" ]; then
    return
  fi

  if [ "$AUTO_CD_HINT_SHOWN" = "1" ]; then
    return
  fi

  AUTO_CD_HINT_SHOWN=1

  local shell_name
  shell_name="${SHELL##*/}"
  if [ -z "$shell_name" ]; then
    shell_name="zsh"
  fi

  local hook_cmd="" rc_hint="reload your shell configuration" rc_file="" hook_present=0
  local hook_marker="# wt shell integration: auto-cd after wt add/path/main/remove/clean"

  case "$shell_name" in
  zsh)
    hook_cmd='wt shell-hook zsh >> ~/.zshrc'
    rc_hint='source ~/.zshrc'
    rc_file="$HOME/.zshrc"
    ;;
  bash)
    hook_cmd='wt shell-hook bash >> ~/.bashrc'
    rc_hint='source ~/.bashrc'
    rc_file="$HOME/.bashrc"
    ;;
  *)
    hook_cmd='wt shell-hook zsh >> ~/.zshrc'
    ;;
  esac

  if [ -n "$rc_file" ] && [ -f "$rc_file" ] && grep -Fq "$hook_marker" "$rc_file"; then
    hook_present=1
  fi

  if [ "$hook_present" -eq 1 ]; then
    info "$(msg auto_cd_pending "$rc_hint")"
    info "$(msg auto_cd_retry)"
    return
  fi

  info "$(msg auto_cd_disabled "$hook_cmd")"
  if [ "$rc_hint" = "reload your shell configuration" ]; then
    info "$(msg auto_cd_reload)"
  else
    info "$(msg auto_cd_execute "$rc_hint")"
  fi
}

format_bold_line() {
  local text="$1"

  if [ -z "$text" ]; then
    printf '%s' "$text"
    return
  fi

  if [ -n "${NO_COLOR:-}" ] || [ ! -t 2 ]; then
    printf '%s' "$text"
    return
  fi

  local start="" end=""
  if command -v tput > /dev/null 2>&1; then
    local ansi_bold ansi_reset
    ansi_bold=$(tput bold 2> /dev/null || true)
    ansi_reset=$(tput sgr0 2> /dev/null || true)
    if [ -n "$ansi_bold$ansi_reset" ]; then
      start="$ansi_bold"
      end="$ansi_reset"
    fi
  fi

  if [ -z "$start" ]; then
    start=$'\033[1m'
    end=$'\033[0m'
  fi

  printf '%s%s%s' "$start" "$text" "$end"
}

format_cyan_bold_line() {
  local text="$1"

  if [ -z "$text" ]; then
    printf '%s' "$text"
    return
  fi

  if [ -n "${NO_COLOR:-}" ] || [ ! -t 2 ]; then
    printf '%s' "$text"
    return
  fi

  local start="" end=""
  if command -v tput > /dev/null 2>&1; then
    local ansi_cyan ansi_bold ansi_reset
    ansi_cyan=$(tput setaf 6 2> /dev/null || true)
    ansi_bold=$(tput bold 2> /dev/null || true)
    ansi_reset=$(tput sgr0 2> /dev/null || true)
    if [ -n "$ansi_cyan$ansi_bold$ansi_reset" ]; then
      start="${ansi_bold}${ansi_cyan}"
      end="$ansi_reset"
    fi
  fi

  if [ -z "$start" ]; then
    start=$'\033[1;36m'
    end=$'\033[0m'
  fi

  printf '%s%s%s' "$start" "$text" "$end"
}

list_effective_width() {
  if [ "${LIST_OUTPUT_WIDTH:-0}" -gt 0 ]; then
    printf '%d\n' "$LIST_OUTPUT_WIDTH"
    return
  fi

  local width=0

  if [ -n "${COLUMNS:-}" ]; then
    case "$COLUMNS" in
    '' | *[!0-9]*) width=0 ;;
    *) width="$COLUMNS" ;;
    esac
  fi

  if [ "$width" -le 0 ] && [ -t 2 ]; then
    local cols=""
    if cols=$(tput cols 2> /dev/null || true); then
      case "$cols" in
      '' | *[!0-9]*) cols=0 ;;
      esac
      width="$cols"
    fi
  fi

  if [ "$width" -le 0 ] && [ -t 1 ]; then
    local cols=""
    if cols=$(tput cols 2> /dev/null || true); then
      case "$cols" in
      '' | *[!0-9]*) cols=0 ;;
      esac
      width="$cols"
    fi
  fi

  if [ "$width" -le 0 ]; then
    width=80
  fi

  LIST_OUTPUT_WIDTH="$width"
  printf '%d\n' "$width"
}

list_render_project_header_box() {
  local display_name="$1"
  local display_path="$2"

  info "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"

  local content_width=72
  local prefix="📁 $display_name"
  local suffix="$display_path"
  local prefix_len=$((${#display_name} + 3))
  local suffix_len=${#display_path}
  local spaces_needed=$((content_width - prefix_len - suffix_len))

  if [ "$spaces_needed" -lt 1 ]; then
    local max_path_len=$((content_width - prefix_len - 4))
    if [ "$max_path_len" -gt 0 ]; then
      suffix="...${display_path: -$max_path_len}"
      suffix_len=${#suffix}
      spaces_needed=$((content_width - prefix_len - suffix_len))
    else
      suffix=""
      suffix_len=0
      spaces_needed=$((content_width - prefix_len))
    fi
  fi

  if [ "$spaces_needed" -lt 0 ]; then
    spaces_needed=0
  fi

  local spaces=""
  local i=0
  while [ "$i" -lt "$spaces_needed" ]; do
    spaces="$spaces "
    i=$((i + 1))
  done

  printf '┃ 📁 %s%s%-*s ┃\n' "$(format_bold_line "$display_name")" "$spaces" "$suffix_len" "$suffix" >&2
  info "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
}

list_render_project_header_sage() {
  local display_name="$1"
  local display_path="$2"

  local header_line
  header_line=$(msg list_global_project_header "$display_name")
  info "$(format_bold_line "$header_line")"
  info "   └─ $display_path"
  info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

list_render_project_header_archer() {
  local display_name="$1"
  local name_segment
  name_segment=$(format_bold_line "$display_name")
  local width
  width=$(list_effective_width)
  local ascii_only=1
  case "$display_name" in
  *[$'\x80'-$'\xFF']*) ascii_only=0 ;;
  esac

  local base_width
  if [ "$ascii_only" -eq 1 ]; then
    base_width=$((6 + ${#display_name}))
  else
    base_width="$width"
  fi

  if [ "$base_width" -ge "$width" ]; then
    info "━━ 📁 ${name_segment}"
    return
  fi
  local filler_units=$((width - base_width - 1))
  local filler=""
  if [ "$filler_units" -gt 0 ]; then
    filler=" $(printf '%*s' "$filler_units" '' | tr ' ' '━')"
  fi
  info "━━ 📁 ${name_segment}${filler}"
}

cmd_list() {
  [ $# -eq 0 ] || die "$(msg list_no_args)"

  local repo_path="$PROJECT_DIR_ABS"
  if [ -z "$repo_path" ]; then
    die "$(msg project_not_found "$WORKING_REPO_PATH")"
  fi

  local display_name
  display_name=$(basename "$repo_path")
  if [ -z "$display_name" ] || [ "$display_name" = "." ]; then
    if [ -n "$PROJECT_SLUG" ]; then
      display_name="$PROJECT_SLUG"
    else
      display_name="$repo_path"
    fi
  fi

  # Convert to ~ format if under home directory
  local display_path="$repo_path"
  if [[ "$repo_path" == "$HOME"* ]]; then
    display_path="~${repo_path#"$HOME"}"
  fi

  if [ "$LIST_THEME" = "sage" ]; then
    list_render_project_header_sage "$display_name" "$display_path"
  elif [ "$LIST_THEME" = "archer" ]; then
    list_render_project_header_archer "$display_name"
  else
    list_render_project_header_box "$display_name" "$display_path"
  fi

  local _prev_primary="$LIST_PRIMARY_WORKTREE_PATH"
  LIST_PRIMARY_WORKTREE_PATH="$repo_path"

  if ! project_print_worktrees "$repo_path"; then
    info "$(msg git_command_failed "$repo_path")"
  fi

  LIST_PRIMARY_WORKTREE_PATH="$_prev_primary"
}

project_emit_worktree_entry() {
  local path="$1"
  local head="$2"
  local branch_raw="$3"
  local flags="$4"

  [ -n "$path" ] || return 0

  local branch_display="$branch_raw"
  if [[ "$branch_display" =~ ^refs/heads/ ]]; then
    branch_display="${branch_display#refs/heads/}"
  elif [[ "$branch_display" =~ ^refs/remotes/ ]]; then
    branch_display="${branch_display#refs/remotes/}"
  fi

  if [ -z "$branch_display" ]; then
    branch_display='-'
  fi

  local status=""
  if [[ " $flags " == *" detached "* ]]; then
    if [ "$branch_display" = '-' ]; then
      branch_display='(detached)'
    else
      status=' [detached]'
    fi
  fi
  if [[ " $flags " == *" bare "* ]]; then
    if [ "$branch_display" = '-' ]; then
      branch_display='(bare)'
    else
      if [ -n "$status" ]; then
        status="$status [bare]"
      else
        status=' [bare]'
      fi
    fi
  fi
  if [[ " $flags " == *" locked "* ]]; then
    if [ -n "$status" ]; then
      status="$status [locked]"
    else
      status=' [locked]'
    fi
  fi
  if [[ " $flags " == *" prunable "* ]]; then
    if [ -n "$status" ]; then
      status="$status [prunable]"
    else
      status=' [prunable]'
    fi
  fi

  local head_short='-------'
  if [ -n "$head" ]; then
    head_short="${head:0:7}"
  fi

  # Extract worktree name from path
  local worktree_name="main"
  local path_basename
  path_basename=$(basename "$path")

  if [ -n "${LIST_PRIMARY_WORKTREE_PATH:-}" ]; then
    if [ "$path" = "$LIST_PRIMARY_WORKTREE_PATH" ]; then
      worktree_name="main"
    else
      # Extract suffix from path like worktree.sh.designlist -> designlist
      local main_basename
      main_basename=$(basename "$LIST_PRIMARY_WORKTREE_PATH")
      if [[ "$path_basename" == "${main_basename}."* ]]; then
        worktree_name="${path_basename#"${main_basename}."}"
      else
        worktree_name="$path_basename"
      fi
    fi
  fi

  # Determine marker: ▶ for current worktree, • for others
  local marker="•"
  local current_dir_abs
  if current_dir_abs=$(cd "$PWD" 2> /dev/null && pwd -P); then
    if [ "$current_dir_abs" = "$path" ]; then
      marker="▶"
    fi
  fi

  # Show path as basename only
  local display_path="$path_basename$status"

  local entry_line
  entry_line=$(msg list_global_worktree_entry "$marker" "$worktree_name" "$branch_display" "$head_short" "$display_path")

  if [ -n "${LIST_PRIMARY_WORKTREE_PATH:-}" ] && [ "$path" = "$LIST_PRIMARY_WORKTREE_PATH" ]; then
    info "$(format_cyan_bold_line "$entry_line")"
  else
    info "$entry_line"
  fi
}

project_print_worktrees() {
  local repo_path="$1"
  local path=""
  local head=""
  local branch=""
  local flags=""
  local rc=0

  while IFS= read -r line || [ -n "$line" ]; do
    if [ -z "$line" ]; then
      project_emit_worktree_entry "$path" "$head" "$branch" "$flags"
      path=""
      head=""
      branch=""
      flags=""
      continue
    fi
    case "$line" in
    worktree\ *)
      path="${line#worktree }"
      ;;
    HEAD\ *)
      head="${line#HEAD }"
      ;;
    branch\ *)
      branch="${line#branch }"
      ;;
    bare)
      flags="$flags bare"
      ;;
    detached)
      flags="$flags detached"
      ;;
    locked*)
      flags="$flags locked"
      ;;
    prunable*)
      flags="$flags prunable"
      ;;
    esac
  done < <(git_at_path "$repo_path" worktree list --porcelain 2> /dev/null) || rc=$?

  if [ -n "$path" ] || [ -n "$head" ] || [ -n "$branch" ]; then
    project_emit_worktree_entry "$path" "$head" "$branch" "$flags"
  fi

  return $rc
}

cmd_list_global() {
  [ $# -eq 0 ] || die "$(msg list_no_args)"

  project_registry_collect
  if [ "$PROJECT_REGISTRY_COUNT" -eq 0 ]; then
    die "$(msg no_projects_configured)"
  fi

  local idx=0
  while [ "$idx" -lt "$PROJECT_REGISTRY_COUNT" ]; do
    local slug="${PROJECT_REGISTRY_SLUGS[$idx]}"
    local repo_path="${PROJECT_REGISTRY_PATHS[$idx]}"
    local display_name="${PROJECT_REGISTRY_DISPLAY_NAMES[$idx]}"
    # Convert to ~ format if under home directory
    local display_path="$repo_path"
    if [[ "$repo_path" == "$HOME"* ]]; then
      display_path="~${repo_path#"$HOME"}"
    fi

    if [ "$LIST_THEME" = "sage" ]; then
      if [ "$idx" -gt 0 ]; then
        info ''
      fi
      list_render_project_header_sage "$display_name" "$display_path"
    elif [ "$LIST_THEME" = "archer" ]; then
      if [ "$idx" -gt 0 ]; then
        info ''
      fi
      list_render_project_header_archer "$display_name"
    else
      list_render_project_header_box "$display_name" "$display_path"
    fi

    if [ -z "$repo_path" ] || [ ! -d "$repo_path" ]; then
      info "$(msg project_path_missing "$display_name")"
    else
      local _prev_primary="$LIST_PRIMARY_WORKTREE_PATH"
      LIST_PRIMARY_WORKTREE_PATH="$repo_path"

      if ! project_print_worktrees "$repo_path"; then
        info "$(msg git_command_failed "$repo_path")"
      fi

      LIST_PRIMARY_WORKTREE_PATH="$_prev_primary"
    fi

    idx=$((idx + 1))
  done
}

cmd_main() {
  [ $# -eq 0 ] || die "$(msg main_no_args)"
  maybe_warn_shell_integration "$PROJECT_DIR_ABS"
  printf '%s\n' "$PROJECT_DIR_ABS"
}

cmd_main_global() {
  [ $# -eq 0 ] || die "$(msg main_no_args)"

  if ! project_prompt_select; then
    if [ "$PROJECT_REGISTRY_COUNT" -eq 0 ]; then
      die "$(msg no_projects_configured)"
    fi
    die "$(msg project_selection_cancelled)"
  fi

  local idx="$PROJECT_SELECTION_INDEX"
  if [ "$idx" -lt 0 ]; then
    die "$(msg project_selection_cancelled)"
  fi

  local target_path="${PROJECT_REGISTRY_PATHS[$idx]}"
  if [ -z "$target_path" ]; then
    die "$(msg project_path_missing "${PROJECT_REGISTRY_SLUGS[$idx]}")"
  fi

  maybe_warn_shell_integration "$target_path"
  printf '%s\n' "$target_path"
}

cmd_path() {
  if [ $# -ne 1 ]; then
    die "$(msg path_requires_name)"
  fi
  local name="$1"
  local target_path
  target_path=$(worktree_path_for "$name")
  if [ ! -d "$target_path" ]; then
    die "$(msg worktree_not_found "$name")"
  fi
  maybe_warn_shell_integration "$target_path"
  printf '%s\n' "$target_path"
}

cmd_path_global() {
  if [ $# -ne 1 ]; then
    die "$(msg path_requires_name)"
  fi

  local name="$1"

  collect_global_worktree_matches "$name"
  local project_count=$PROJECT_REGISTRY_COUNT
  if [ "$project_count" -eq 0 ]; then
    die "$(msg no_projects_configured)"
  fi

  local matches=${#MATCH_WORKTREE_NAMES[@]}
  if [ "$matches" -eq 0 ]; then
    die "$(msg worktree_not_found "$name")"
  fi

  if [ "$matches" -eq 1 ]; then
    WORKTREE_SELECTION_INDEX=0
  else
    if ! worktree_prompt_select_global; then
      die "$(msg project_selection_cancelled)"
    fi
  fi

  local selected="$WORKTREE_SELECTION_INDEX"
  if [ "$selected" -lt 0 ]; then
    die "$(msg project_selection_cancelled)"
  fi

  local target_path="${MATCH_WORKTREE_PATHS[$selected]}"
  maybe_warn_shell_integration "$target_path"
  printf '%s\n' "$target_path"
}

cmd_add() {
  local name="$1"
  shift || true

  [ -n "$name" ] || die "$(msg add_requires_name)"
  if is_help_token "$name"; then
    command_usage add
    return
  fi
  if [[ "$name" == -* ]]; then
    die "$(msg add_unknown_option "$name")"
  fi
  if ! validate_worktree_name "$name"; then
    die "$(msg invalid_worktree_name "$name")"
  fi

  ensure_within_project_directory

  local run_install="$INSTALL_DEPS_ENABLED"
  local run_dev="$SERVE_DEV_ENABLED"
  local copy_env="$COPY_ENV_ENABLED"
  local branch=""
  local numeric_name=""
  local port_candidate=""
  local effective_port=""
  local skip_dev=0
  local skip_dev_port=""
  local skip_dev_reason=""
  local base_branch=""
  if base_branch=$(project_current_branch 2> /dev/null); then
    :
  fi

  if [ -z "$base_branch" ]; then
    die "$(msg project_branch_required)"
  fi

  if [[ "$name" =~ ^[0-9]+$ ]]; then
    numeric_name="$name"
    port_candidate="$name"
    if [ "$numeric_name" -ge 1 ] && [ "$numeric_name" -lt 1024 ]; then
      info "$(msg reserved_port "$numeric_name")"
    elif [ "$numeric_name" -gt 65535 ]; then
      info "$(msg port_out_of_range "$numeric_name")"
    fi
  fi

  if [ -z "$port_candidate" ] && [[ "$name" =~ ([0-9]+)$ ]]; then
    port_candidate="${BASH_REMATCH[1]}"
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
    -h | --help | help)
      command_usage add
      return
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "$(msg add_unknown_option "$1")"
      ;;
    *)
      die "$(msg unexpected_extra_argument "$1")"
      ;;
    esac
    shift || true
  done

  if [ $# -gt 0 ]; then
    die "$(msg unexpected_extra_argument "$1")"
  fi

  if [ "$run_dev" -eq 1 ]; then
    effective_port=$(port_from_name "$name")

    if [ -z "$effective_port" ] && [ -n "$port_candidate" ]; then
      if [ "$port_candidate" -lt 1024 ]; then
        skip_dev=1
        skip_dev_port="$port_candidate"
        skip_dev_reason="reserved"
      elif [ "$port_candidate" -gt 65535 ]; then
        info "$(msg fallback_default_port)"
      fi
    fi
  fi

  local worktree_path
  worktree_path=$(worktree_path_for "$name")

  if [ -e "$worktree_path" ]; then
    die "$(msg worktree_exists "$worktree_path")"
  fi

  ensure_branch_prefix_for_add

  if [ -z "$branch" ]; then
    branch=$(branch_for "$name")
  fi

  info "$(msg creating_worktree "$worktree_path" "$branch")"
  git_project worktree add -b "$branch" "$worktree_path" "$base_branch" >&2
  info "$(msg worktree_created)"

  if [ "$copy_env" -eq 1 ]; then
    if [ ${#COPY_ENV_FILE_SELECTION[@]} -gt 0 ]; then
      local env_file
      for env_file in "${COPY_ENV_FILE_SELECTION[@]}"; do
        [ -n "$env_file" ] || continue
        copy_env_file "$env_file" "$worktree_path"
      done
    fi
  fi

  local install_command="$INSTALL_DEPS_COMMAND"
  local serve_command="$SERVE_DEV_COMMAND"
  local install_detected=0
  local serve_detected=0

  if [ "$run_install" -eq 1 ] && [ -z "$install_command" ]; then
    if install_command=$(infer_install_command "$worktree_path"); then
      info "$(msg install_detected "$install_command")"
      install_detected=1
    fi
  fi

  if [ "$run_dev" -eq 1 ] && [ -z "$serve_command" ]; then
    if serve_command=$(infer_serve_command "$worktree_path"); then
      info "$(msg serve_detected "$serve_command")"
      serve_detected=1
    fi
  fi

  if [ "$install_detected" -eq 1 ]; then
    config_set "add.install-deps.command" "$install_command"
  fi

  if [ "$serve_detected" -eq 1 ]; then
    config_set "add.serve-dev.command" "$serve_command"
  fi

  if [ "$run_install" -eq 1 ]; then
    run_install_command "$worktree_path" "$install_command"
  fi

  if ! run_configured_hook_command "$ADD_POST_COMMAND" "$worktree_path" "add.post" "$name" "$worktree_path" "$branch"; then
    die "add post-command failed"
  fi

  if [ "$run_dev" -eq 1 ]; then
    if [ "$skip_dev" -eq 1 ]; then
      if [ "$skip_dev_reason" = "reserved" ]; then
        info "$(msg dev_skipped_reserved_port "$skip_dev_port")"
      elif [ "$skip_dev_reason" = "no_port" ]; then
        info "$(msg dev_skipped_no_port)"
      fi
    else
      start_dev_server "$worktree_path" "$serve_command" "$effective_port"
    fi
  else
    info "$(msg dev_skipped_config)"
  fi

  info "$(msg worktree_ready "$worktree_path")"
  maybe_warn_shell_integration "$worktree_path"
  printf '%s\n' "$worktree_path"
}

config_print_effective() {
  local has_language_line=0
  local has_theme_line=0
  local has_serve_ready_timeout_line=0
  local has_serve_settle_timeout_line=0

  if [ -f "$CONFIG_FILE" ]; then
    if [ -s "$CONFIG_FILE" ]; then
      if grep -q '^language=' "$CONFIG_FILE" 2> /dev/null; then
        has_language_line=1
      fi
      if grep -q '^theme=' "$CONFIG_FILE" 2> /dev/null; then
        has_theme_line=1
      fi
      if grep -q '^add\.serve-dev\.ready-timeout=' "$CONFIG_FILE" 2> /dev/null; then
        has_serve_ready_timeout_line=1
      fi
      if grep -q '^add\.serve-dev\.settle-timeout=' "$CONFIG_FILE" 2> /dev/null; then
        has_serve_settle_timeout_line=1
      fi
      cat "$CONFIG_FILE"
    else
      info "$(msg config_list_empty "$CONFIG_FILE")"
    fi
  else
    if [ "$CONFIG_FILE_IS_ENV_OVERRIDE" -eq 1 ]; then
      die "$(msg config_file_missing "$CONFIG_FILE")"
    fi
    info "$(msg config_list_empty "$CONFIG_FILE")"
  fi

  local effective_language
  if effective_language=$(config_get_or_default "language" 2> /dev/null); then
    :
  else
    effective_language="$CONFIG_DEFAULT_LANGUAGE"
  fi

  if [ "$has_language_line" -eq 0 ]; then
    printf 'language=%s\n' "$effective_language"
  fi

  local effective_theme
  if effective_theme=$(config_get_or_default "theme" 2> /dev/null); then
    :
  else
    effective_theme="$CONFIG_DEFAULT_THEME"
  fi

  if [ "$has_theme_line" -eq 0 ]; then
    printf 'theme=%s\n' "$effective_theme"
  fi

  local effective_ready_timeout
  if effective_ready_timeout=$(config_get_or_default "add.serve-dev.ready-timeout" 2> /dev/null); then
    :
  else
    effective_ready_timeout="$CONFIG_DEFAULT_SERVE_DEV_READY_TIMEOUT"
  fi

  if [ "$has_serve_ready_timeout_line" -eq 0 ]; then
    printf 'add.serve-dev.ready-timeout=%s\n' "$effective_ready_timeout"
  fi

  local effective_settle_timeout
  if effective_settle_timeout=$(config_get_or_default "add.serve-dev.settle-timeout" 2> /dev/null); then
    :
  else
    effective_settle_timeout="$CONFIG_DEFAULT_SERVE_DEV_SETTLE_TIMEOUT"
  fi

  if [ "$has_serve_settle_timeout_line" -eq 0 ]; then
    printf 'add.serve-dev.settle-timeout=%s\n' "$effective_settle_timeout"
  fi

  return 0
}

config_usage() {
  case "$LANGUAGE" in
  zh)
    cat << 'CONFIG_USAGE_ZH'
wt config - 查看或更新 worktree.sh 配置

子命令:
  wt config list                 显示生效配置（包含默认值）
  wt config get <key> [--stored] 默认输出生效配置项；使用 --stored 仅读取配置文件
  wt config set <key> <value>    将配置写入 ~/.worktree.sh
  wt config unset <key>          从 ~/.worktree.sh 移除配置

快捷方式:
  wt config <key>                等同于 get（生效值）
  wt config --stored <key>       等同于 get --stored
  wt config <key> <value>        等同于 set

支持的键:
  language                        CLI 显示语言（en|zh，默认 en，使用 "wt lang" 切换）
  repo.path                       默认维护的仓库根目录（由 wt init 设置）
  add.branch-prefix               新 worktree 分支名前缀（默认 feat/，若已存在同名分支会依次回退到 feature/、ft/）
  add.copy-env.enabled            是否在 wt add 时复制环境文件
  add.copy-env.files              被复制的环境文件列表（JSON 数组）
  add.install-deps.enabled        是否在 wt add 时安装依赖
  add.install-deps.command        安装依赖使用的命令（留空则自动推断）
  add.serve-dev.enabled           是否在 wt add 后启动开发服务
  add.serve-dev.command           启动开发服务的命令（留空则自动推断）
  add.serve-dev.logging-path      Dev 服务日志所在子目录（默认: tmp）
  add.serve-dev.ready-timeout     等待端口开始监听的秒数（默认: 60）
  add.serve-dev.settle-timeout    端口就绪后继续观察的秒数（默认: 5，用于兼容短命启动脚本）
  theme                           wt list 的显示主题（box 或 sage，默认 box，可用 "wt theme" 切换）

语言与主题:
  全局语言使用 "wt lang" 管理；全局主题使用 "wt theme" 管理。项目级配置仍可通过 wt config 调整。
CONFIG_USAGE_ZH
    ;;
  *)
    cat << 'CONFIG_USAGE_EN'
wt config - Inspect or update worktree.sh configuration

Subcommands:
  wt config list                 Show effective configuration (includes defaults)
  wt config get <key> [--stored] Print effective value; add --stored to read the raw file only
  wt config set <key> <value>    Persist value in ~/.worktree.sh
  wt config unset <key>          Remove key from ~/.worktree.sh

Shortcuts:
  wt config <key>                Shortcut for effective get
  wt config --stored <key>       Shortcut for get --stored
  wt config <key> <value>        Shortcut for set

Supported keys:
  language                        CLI language (en or zh; default: en). Use "wt lang" to change.
  repo.path                       Root directory of the tracked repository (set by wt init)
  add.branch-prefix               Branch name prefix used for new worktrees (default: feat/; falls back to feature/ then ft/ when conflicts exist)
  add.copy-env.enabled            Whether wt add copies environment files
  add.copy-env.files              Environment files to copy (JSON array)
  add.install-deps.enabled        Whether wt add installs dependencies
  add.install-deps.command        Command used to install dependencies (empty = auto-detect)
  add.serve-dev.enabled           Whether wt add starts the dev service
  add.serve-dev.command           Command used to start the dev service (empty = auto-detect)
  add.serve-dev.logging-path      Subdirectory for dev logs (default: tmp)
  add.serve-dev.ready-timeout     Seconds to wait for the dev port to start listening (default: 60)
  add.serve-dev.settle-timeout    Extra seconds to observe the port after readiness (default: 5; useful for short-lived launcher scripts)
  theme                           Theme for wt list output (box or sage; default box). Use "wt theme" to change.

Language & theme:
  Manage language via "wt lang"; manage theme via "wt theme". Project-level overrides remain available through wt config.
CONFIG_USAGE_EN
    ;;
  esac
}
