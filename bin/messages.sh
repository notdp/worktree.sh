# shellcheck shell=bash

msg_en() {
  local key="${1:-}"
  shift || true
  case "$key" in
  copy_env_file)
    printf '📄 Copy %s → %s' "$1" "$2"
    ;;
  copy_env_missing)
    printf '⚠️  Skipping copy; source not found: %s' "$1"
    ;;
  command_not_found)
    printf '⚠️  Command not available: %s; skipping' "$1"
    ;;
  start_dev_port)
    printf '🚀 Starting dev command (port %s)' "$1"
    ;;
  start_dev_default)
    printf '🚀 Starting dev command'
    ;;
  start_dev_generic)
    printf '🚀 Starting dev command'
    ;;
  dev_started_port)
    printf '✅ Dev command is ready; port %s is listening' "$1"
    ;;
  dev_started_default)
    printf '✅ Dev command running'
    ;;
  dev_failed)
    printf '⚠️ Dev command may not have started correctly (PID: %s); check %s' "$1" "$2"
    ;;
  dev_timeout)
    printf '⚠️ Dev command did not become ready on port %s within %s seconds; check %s' "$1" "$2" "$3"
    ;;
  dev_log_hint)
    printf '📝 Dev command log: tail -f %s' "$1"
    ;;
  install_skipped_no_command)
    printf '⚙️  Dependencies skipped (no command configured)'
    ;;
  install_skipped_missing_lock)
    printf '⚠️  Skipping dependency install (%s): no package-lock.json or npm-shrinkwrap.json found' "$1"
    ;;
  install_detected)
    printf '🔍 Auto-detected install command: %s' "$1"
    ;;
  serve_detected)
    printf '🔍 Auto-detected dev command: %s' "$1"
    ;;
  dev_command)
    printf '🚀 Dev command: %s' "$1"
    ;;
  dev_skipped_no_command)
    printf '⚙️  Dev command skipped (no command configured)'
    ;;
  dev_skipped_no_port)
    printf '⚙️  Dev command skipped (no port inferred from worktree name)'
    ;;
  auto_cd_pending)
    printf '💡 wt auto-cd appears inactive. Try running: %s' "$1"
    ;;
  auto_cd_retry)
    printf '   If that command fails, reopen your terminal.'
    ;;
  auto_cd_disabled)
    printf '💡 wt auto-cd is not enabled. To jump automatically, run: %s' "$1"
    ;;
  auto_cd_reload)
    printf '   Then reload your shell (e.g. open a new terminal).'
    ;;
  auto_cd_execute)
    printf '   Then run: %s (or reopen the terminal).' "$1"
    ;;
  reserved_port)
    printf '⚠️  %s is a reserved port (1-1023); the dev command will not use it.' "$1"
    ;;
  port_out_of_range)
    printf '⚠️  %s is outside the valid port range (65535); falling back to default port.' "$1"
    ;;
  fallback_default_port)
    printf '⚠️  Using default port 3000 for the dev command.'
    ;;
  dev_skipped_reserved_port)
    printf '⚙️  Dev command skipped because %s is a reserved port (<1024)' "$1"
    ;;
  creating_worktree)
    printf '🔧 Creating worktree: %s (branch %s)' "$1" "$2"
    ;;
  add_branch_prefix_fallback)
    printf '⚠️  Branch "%s" already exists; using branch prefix %s for this worktree\n   Persist via: wt config set add.branch-prefix %s' "$1" "$2" "$3"
    ;;
  add_branch_prefix_exhausted)
    printf 'wt add could not find a usable branch prefix (example: %s); configure add.branch-prefix and retry.' "$1"
    ;;
  worktree_created)
    printf '✅ Worktree created'
    ;;
  installing_dependencies)
    printf '📦 Installing dependencies (%s)' "$1"
    ;;
  dev_skipped_config)
    printf '⚙️  Dev command skipped per configuration'
    ;;
  worktree_ready)
    printf '✅ Worktree ready: %s' "$1"
    ;;
  init_set_project)
    printf '\n\033[94;1m%-11s\033[0m → \033[32m%s\033[0m\n' 'repo.path' "$1"
    ;;
  init_branch_option_deprecated)
    printf '  repo.branch has been removed; ignoring requested branch "%s"\n' "$1"
    ;;
  init_slug_failed)
    printf 'failed to derive project slug from the current repository'
    ;;
  init_slug_mismatch)
    printf 'existing project %s points to %s (current repo: %s); aborting' "$1" "$2" "$3"
    ;;
  init_created_project)
    printf '\033[94;1m%-11s\033[0m → \033[32m%s\033[0m\n' 'config file' "$2"
    ;;
  init_done)
    printf 'wt init completed successfully.\n'
    ;;
  lang_set_requires)
    printf 'wt lang set requires exactly one argument (en or zh)'
    ;;
  lang_unknown_command)
    printf 'Unknown wt lang command: %s' "$1"
    ;;
  lang_prompt_select)
    printf 'Choose interface language:'
    ;;
  lang_option_en_label)
    printf 'English'
    ;;
  lang_option_en_hint)
    printf 'English interface'
    ;;
  lang_option_zh_label)
    printf '中文 (Chinese)'
    ;;
  lang_option_zh_hint)
    printf 'Chinese interface'
    ;;
  lang_option_reset_label)
    printf 'Reset to default'
    ;;
  lang_option_reset_hint)
    printf 'Restore English (default)'
    ;;
  lang_set_success)
    printf 'Language set to %s (%s)' "$1" "$2"
    ;;
  lang_reset_success)
    printf 'Language reset to %s (%s)' "$1" "$2"
    ;;
  lang_current)
    printf 'Current language: %s (%s)' "$1" "$2"
    ;;
  theme_set_requires)
    printf 'theme set requires <box|sage|archer>'
    ;;
  invalid_theme)
    printf 'unknown theme: %s (expected box, sage, or archer)' "$1"
    ;;
  theme_set_success)
    printf 'Theme set to %s' "$2"
    ;;
  theme_reset_success)
    printf 'Theme reset to %s' "$2"
    ;;
  theme_current)
    printf 'Current theme: %s' "$2"
    ;;
  theme_option_box_label)
    printf 'box'
    ;;
  theme_option_box_hint)
    printf 'Use framed headers for wt list'
    ;;
  theme_option_sage_label)
    printf 'sage'
    ;;
  theme_option_sage_hint)
    printf 'Use minimal headers for wt list (includes path)'
    ;;
  theme_option_archer_label)
    printf 'archer'
    ;;
  theme_option_archer_hint)
    printf 'Use compact headers without project path'
    ;;
  theme_option_reset_label)
    printf 'Reset to default'
    ;;
  theme_option_reset_hint)
    printf 'Restore boxed theme'
    ;;
  theme_prompt_select)
    printf 'Select a theme for wt list output:'
    ;;
  theme_selection_cancelled)
    printf 'Theme selection cancelled'
    ;;
  theme_unknown_command)
    printf 'unknown theme command: %s' "$1"
    ;;
  theme_usage)
    cat << 'THEME_USAGE_EN'
wt theme - Manage worktree.sh list layout theme

Interactive (TTY):
  wt theme                 Choose theme with arrow keys

Non-interactive:
  wt theme get                     Print current theme code
  wt theme set <box|sage|archer>   Switch theme
  wt theme reset                   Reset to default (box)
  wt theme box|sage|archer         Shortcut for wt theme set
  wt theme help                    Show this help
THEME_USAGE_EN
    ;;
  lang_usage)
    cat << 'LANG_USAGE_EN'
wt lang - Manage worktree.sh interface language

Interactive (TTY):
  wt lang                  Choose language with arrow keys

Non-interactive:
  wt lang get              Print current language code
  wt lang set <en|zh>      Switch language
  wt lang reset            Reset to default (English)
  wt lang en|zh            Shortcut for wt lang set
  wt lang help             Show this help
LANG_USAGE_EN
    ;;
  help_usage)
    cat << 'HELP_USAGE_EN'
wt help - Show global or command-specific help

Usage:
  wt help
  wt help <command>

Examples:
  wt help add
  wt help sync

Tip:
  Every core command also accepts --help, for example:
  wt add --help
HELP_USAGE_EN
    ;;
  list_usage)
    cat << 'LIST_USAGE_EN'
wt list - Show known worktrees for the current project

Usage:
  wt
  wt list
  wt list --help

Notes:
  - Inside a configured project, shows that project's main worktree plus siblings.
  - Outside a configured project, use wt help for command discovery or wt init in a repo first.
LIST_USAGE_EN
    ;;
  main_usage)
    cat << 'MAIN_USAGE_EN'
wt main - Print the main worktree path

Usage:
  wt main
  wt main --help

Notes:
  - With shell-hook installed, calling wt main jumps back to the main repository automatically.
  - Without shell-hook, it prints the absolute path so you can cd manually.
MAIN_USAGE_EN
    ;;
  path_usage)
    cat << 'PATH_USAGE_EN'
wt path - Print a worktree path without switching directories

Usage:
  wt path <name>
  wt path --help

Examples:
  wt path 3000
  wt path ui9083
PATH_USAGE_EN
    ;;
  add_usage)
    cat << 'ADD_USAGE_EN'
wt add - Create a new worktree from the current branch

Usage:
  wt add <name>
  wt add --help

What <name> controls:
  - Worktree path suffix (for example ../project.<name>)
  - Branch suffix (for example feat/<name>)
  - Dev PORT when the name is numeric or ends with digits

Port rules:
  - wt add 9083      -> PORT=9083
  - wt add ui9083    -> worktree name ui9083, branch feat/ui9083, PORT=9083
  - Ports below 1024 are treated as reserved and are not passed to the dev command
  - Ports above 65535 fall back to the default dev port behavior

Examples:
  wt add 3000
  wt add ui9083
  wt add feat-auth
ADD_USAGE_EN
    ;;
  merge_usage)
    cat << 'MERGE_USAGE_EN'
wt merge - Merge a worktree branch back into the current base branch

Usage:
  wt merge <name>
  wt merge --help

Examples:
  wt merge 3000
  wt merge ui9083

Notes:
  - Run from the main worktree on the branch you want to merge into.
  - Both the main worktree and target worktree must be clean.
MERGE_USAGE_EN
    ;;
  sync_usage)
    cat << 'SYNC_USAGE_EN'
wt sync - Apply staged changes from the main worktree into other worktrees

Usage:
  wt sync all
  wt sync <name> [name ...]
  wt sync --help

Examples:
  wt sync all
  wt sync 3000 ui9083

Notes:
  - Sync reads the staged diff from the current main worktree.
  - Target worktrees must be clean before syncing.
SYNC_USAGE_EN
    ;;
  remove_usage)
    cat << 'REMOVE_USAGE_EN'
wt rm - Remove worktrees and their feature branches

Usage:
  wt rm [name ...]
  wt rm --help

Examples:
  wt rm 3000
  wt rm ui9083
  wt rm          # Remove the current worktree when run inside it

Notes:
  - Protected or mismatched branches are skipped instead of deleted.
  - Alias: wt remove
REMOVE_USAGE_EN
    ;;
  clean_usage)
    cat << 'CLEAN_USAGE_EN'
wt clean - Remove numeric worktrees for the current project

Usage:
  wt clean
  wt clean --help

Notes:
  - Matches worktrees whose suffix is only digits, such as 3000 or 9083.
  - Leaves named worktrees such as ui9083 or feat-auth untouched.
CLEAN_USAGE_EN
    ;;
  detach_usage)
    cat << 'DETACH_USAGE_EN'
wt detach - Remove all tracked worktrees for a project

Usage:
  wt detach [-y|--yes] [project-slug]
  wt detach --help

Examples:
  wt detach
  wt detach -y
  wt detach my-project

Notes:
  - In a project workspace, the current project slug is used by default.
  - In global mode, wt can prompt you to choose a project when no slug is provided.
DETACH_USAGE_EN
    ;;
  init_prompt_repo_path)
    printf 'Repository path for wt to track?'
    ;;
  init_prompt_copy_env)
    printf 'Copy environment files automatically?'
    ;;
  init_prompt_copy_env_files)
    printf 'Which environment files should be copied?'
    ;;
  init_prompt_install_command)
    printf 'Which command installs dependencies?'
    ;;
  init_prompt_install_custom)
    printf 'Enter a custom install command:'
    ;;
  init_install_option_npm_ci_hint)
    printf 'uses package-lock.json'
    ;;
  init_install_option_npm_install_hint)
    printf 'skips lockfile optimizations'
    ;;
  init_install_option_pnpm_install_hint)
    printf 'requires pnpm-lock.yaml'
    ;;
  init_install_option_yarn_install_hint)
    printf 'requires yarn.lock'
    ;;
  init_install_option_bun_install_hint)
    printf 'requires Bun'
    ;;
  init_install_option_uv_sync_hint)
    printf 'Python projects using uv'
    ;;
  init_install_option_poetry_install_hint)
    printf 'Python projects using Poetry'
    ;;
  init_install_option_pipenv_install_hint)
    printf 'Python projects using Pipenv'
    ;;
  init_install_option_pdm_install_hint)
    printf 'Python projects using PDM'
    ;;
  init_install_option_rye_install_hint)
    printf 'Python projects using Rye'
    ;;
  init_install_option_hatch_install_hint)
    printf 'Python projects using Hatch'
    ;;
  init_install_option_conda_hint)
    printf 'Python projects using Conda environment files'
    ;;
  init_install_option_pip_create_venv_hint)
    printf 'Creates a virtualenv and installs dependencies'
    ;;
  init_install_option_pip_requirements_hint)
    printf 'Installs from requirements.txt'
    ;;
  init_install_option_skip_label)
    printf 'None'
    ;;
  init_install_option_skip_hint)
    printf 'Skip automatic dependency installation'
    ;;
  init_install_option_custom_label)
    printf 'Custom command'
    ;;
  init_install_option_custom_hint)
    printf 'Provide your own install command'
    ;;
  init_install_option_detected_hint)
    printf 'Detected from repository files'
    ;;
  init_install_option_existing_hint)
    printf 'Existing project configuration'
    ;;
  init_prompt_serve_command)
    printf 'Which command starts the dev server?'
    ;;
  init_prompt_serve_custom)
    printf 'Enter a custom dev command:'
    ;;
  init_serve_option_npm_run_dev_hint)
    printf 'npm run dev (package.json scripts)'
    ;;
  init_serve_option_pnpm_dev_hint)
    printf 'pnpm dev (package.json scripts)'
    ;;
  init_serve_option_yarn_dev_hint)
    printf 'yarn dev (package.json scripts)'
    ;;
  init_serve_option_bun_dev_hint)
    printf 'bun dev (package.json scripts)'
    ;;
  init_serve_option_uv_run_hint)
    printf 'uv run (Python dev server)'
    ;;
  init_serve_option_poetry_run_hint)
    printf 'poetry run (manages virtualenv automatically)'
    ;;
  init_serve_option_pipenv_run_hint)
    printf 'pipenv run (manages virtualenv automatically)'
    ;;
  init_serve_option_pdm_run_hint)
    printf 'pdm run (manages virtualenv automatically)'
    ;;
  init_serve_option_rye_run_hint)
    printf 'rye run (manages virtualenv automatically)'
    ;;
  init_serve_option_hatch_run_hint)
    printf 'hatch run (manages virtualenv automatically)'
    ;;
  init_serve_option_conda_hint)
    printf 'conda run (uses the Conda environment)'
    ;;
  init_serve_option_pip_venv_hint)
    printf 'Use commands from the project virtualenv'
    ;;
  init_serve_option_manage_runserver_hint)
    printf 'Django manage.py runserver'
    ;;
  init_serve_option_python_app_hint)
    printf 'python app.py'
    ;;
  init_serve_option_skip_label)
    printf 'None'
    ;;
  init_serve_option_skip_hint)
    printf 'Skip automatic dev server startup'
    ;;
  init_serve_option_custom_label)
    printf 'Custom command'
    ;;
  init_serve_option_custom_hint)
    printf 'Provide your own dev command'
    ;;
  init_serve_option_detected_hint)
    printf 'Detected from repository files'
    ;;
  init_serve_option_existing_hint)
    printf 'Existing project configuration'
    ;;
  init_prompt_serve_logging_path)
    printf 'Where should dev logs be written? (leave empty to disable)'
    ;;
  init_prompt_branch_prefix)
    printf 'Preferred worktree branch prefix?'
    ;;
  init_prompt_branch_custom)
    printf 'Enter a custom branch prefix:'
    ;;
  init_branch_option_current_hint)
    printf 'Current configuration'
    ;;
  init_branch_option_default_hint)
    printf 'Default prefix (recommended)'
    ;;
  init_branch_option_alternative_hint)
    printf 'Common alternative prefix'
    ;;
  init_branch_option_skip_label)
    printf 'Keep current setting'
    ;;
  init_branch_option_skip_hint)
    printf 'Leave the prefix unchanged'
    ;;
  init_branch_option_custom_label)
    printf 'Custom prefix'
    ;;
  init_branch_option_custom_hint)
    printf 'Provide your own branch prefix'
    ;;
  aborted)
    printf 'Aborted'
    ;;
  removing_worktree)
    printf '🗑️  Removing worktree: %s' "$1"
    ;;
  removed_branch)
    printf '🗂️  Deleted branch %s' "$1"
    ;;
  worktree_removed)
    printf '✅ Removed worktree %s' "$1"
    ;;
  current_worktree_removed)
    printf '📁 Current worktree removed; switching back to the main directory'
    ;;
  merge_requires_name)
    printf 'merge requires a worktree name (e.g. wt merge 123)'
    ;;
  merge_invalid_target)
    printf 'merge resolves %s (worktree %s) → %s (main workspace); wt merge expects a feature branch. Rename the worktree or adjust the branch prefix.' "$1" "$2" "$3"
    ;;
  merge_base_dirty)
    printf 'main workspace has uncommitted changes; commit or stash before merging'
    ;;
  merge_branch_not_found)
    printf 'feature branch not found: %s' "$1"
    ;;
  merge_feat_dirty)
    printf 'worktree %s has uncommitted changes; commit or stash before merging' "$1"
    ;;
  merge_no_commits)
    printf 'no new commits on %s relative to %s; nothing to merge' "$1" "$2"
    ;;
  merge_start)
    printf '🔀 Merging %s into %s' "$1" "$2"
    ;;
  merge_conflict_abort)
    printf '⚠️ Merge conflict; merge manually or enlist an LLM to resolve/conflict-fix/port changes, then rerun'
    ;;
  merge_done)
    printf '✅ Merge complete: %s → %s' "$1" "$2"
    ;;
  merge_cleanup_hint)
    printf '🧹 Consider cleaning up the worktree with: wt rm %s' "$1"
    ;;
  project_branch_required)
    printf 'main workspace is on a detached HEAD; checkout a branch and retry'
    ;;
  project_directory_required)
    printf 'run this command from %s or one of its subdirectories' "$1"
    ;;
  sync_requires_target)
    printf 'sync requires "all" or one or more worktree names'
    ;;
  sync_invalid_all)
    printf 'sync "all" cannot be combined with additional names'
    ;;
  sync_base_dirty)
    printf 'main workspace has unstaged or untracked changes; commit or stash before syncing'
    ;;
  sync_skip_base)
    printf '⚙️  Skipping base workspace (%s)' "$1"
    ;;
  sync_no_targets)
    printf 'no worktrees found to sync'
    ;;
  sync_no_staged)
    printf 'no staged changes to sync; run git add first'
    ;;
  sync_patch_failed)
    printf 'failed to prepare staged diff for syncing'
    ;;
  sync_target_dirty)
    printf 'worktree %s is dirty (%s); commit or stash before syncing' "$1" "$2"
    ;;
  sync_apply_failed)
    printf '⚠️  Failed to sync staged changes to %s; apply manually' "$1"
    ;;
  sync_apply_start)
    printf '📤 Syncing staged changes to %s' "$1"
    ;;
  sync_apply_done)
    printf '✅ Synced %s' "$1"
    ;;
  sync_done)
    printf '✅ Sync complete (%s worktree(s) updated)' "$1"
    ;;
  cleaning_worktree)
    printf '🧹 Cleaning worktree: %s' "$1"
    ;;
  cleaned_count)
    printf '✅ Cleaned %s worktree(s)' "$1"
    ;;
  cleaned_none)
    printf '✅ No numeric worktrees to clean'
    ;;
  clean_switch_back)
    printf '📁 Current worktree was cleaned; switching back to the main directory'
    ;;
  remove_confirm_prompt)
    printf 'Remove worktree %s? [Y/n]' "$1"
    ;;
  remove_confirm_prompt_global)
    printf 'Remove %s from project %s at %s? [Y/n]' "$1" "$2" "$3"
    ;;
  remove_failed)
    printf 'Failed to remove %s' "$1"
    ;;
  remove_branch_skip_protected)
    printf '⚠️  Skipping branch deletion for %s: protected branch %s (expected exact match %s)' "$1" "$2" "$3"
    ;;
  remove_branch_skip_mismatch)
    printf '⚠️  Skipping branch deletion for %s: current branch %s does not exactly match expected %s' "$1" "$2" "$3"
    ;;
  remove_branch_skip_missing)
    printf '⚠️  Skipping branch deletion for %s: current branch could not be verified (expected exact match %s)' "$1" "$2"
    ;;
  detach_prompt_worktree)
    printf 'Remove worktree %s? [Y/n]' "$1"
    ;;
  detach_abort_user)
    printf 'Detach aborted by user'
    ;;
  detach_remove_failed)
    printf 'Failed to remove %s: %s' "$1" "$2"
    ;;
  detach_summary_removed)
    printf 'Removed %s worktree(s)' "$1"
    ;;
  detach_summary_failed)
    printf 'Failed to remove %s (%s)' "$1" "$2"
    ;;
  detach_summary_skipped)
    printf 'Skipped %s pending worktree(s)' "$1"
    ;;
  detach_prompt_project)
    printf 'Detach project %s? [Y/n]' "$1"
    ;;
  detach_done)
    printf '✅ Detached project %s' "$1"
    ;;
  detach_project_missing)
    printf 'Project %s is not configured; nothing to detach' "$1"
    ;;
  detach_no_projects)
    printf 'No projects are registered yet; run wt init first'
    ;;
  detach_unknown_option)
    printf 'unknown option for detach: %s' "$1"
    ;;
  clean_confirm_prompt)
    printf 'Remove numeric worktree %s from project %s (%s)? [Y/n]' "$1" "$2" "$3"
    ;;
  select_navigation_hint)
    printf '(Use ↑/↓ or j/k to move, Enter to confirm, Ctrl+C to cancel. Digits jump directly.)'
    ;;
  prompt_yes_label)
    printf 'Yes'
    ;;
  prompt_no_label)
    printf 'No'
    ;;
  prompt_choice_hint)
    printf '%s' '- Use arrow keys. Enter to confirm, Ctrl+C to cancel.'
    ;;
  prompt_default_hint)
    printf 'Default (press Enter to keep): %s' "$1"
    ;;
  prompt_empty_display)
    printf '(empty)'
    ;;
  select_project_prompt)
    printf 'Select a project:'
    ;;
  select_project_option)
    if [ -n "${3:-}" ]; then
      printf '  [%d] %s (%s) — %s' "$1" "$2" "$3" "$4"
    else
      printf '  [%d] %s — %s' "$1" "$2" "$4"
    fi
    ;;
  select_project_input)
    printf 'Enter a number (1-%s) or press Enter to cancel:' "$1"
    ;;
  select_project_invalid)
    printf 'Please enter a number between 1 and %s.' "$1"
    ;;
  select_worktree_prompt)
    printf 'Select a matching worktree:'
    ;;
  select_worktree_option)
    printf '  [%d] %s (project %s) — %s' "$1" "$2" "$3" "$4"
    ;;
  select_worktree_input)
    printf 'Enter a number (1-%s) or press Enter to cancel:' "$1"
    ;;
  select_worktree_invalid)
    printf 'Please enter a number between 1 and %s.' "$1"
    ;;
  config_set_requires)
    printf 'config set requires <key> <value>'
    ;;
  temp_file_failed)
    printf 'failed to allocate temp file'
    ;;
  config_unset_requires)
    printf 'config unset requires <key>'
    ;;
  config_file_missing)
    printf 'config file not found: %s' "$1"
    ;;
  config_key_not_set)
    printf 'config key not set: %s' "$1"
    ;;
  config_update_failed)
    printf 'failed to update config'
    ;;
  git_required)
    printf 'git is required'
    ;;
  project_not_found)
    printf 'project directory not found: %s' "$1"
    ;;
  project_dir_unset)
    printf 'wt is not configured yet; run "wt init" inside your repository first'
    ;;
  project_selection_cancelled)
    printf 'Project selection cancelled'
    ;;
  project_path_missing)
    printf 'Project %s has no valid repo.path; run wt init inside the repository again' "$1"
    ;;
  git_command_failed)
    printf 'git command failed in %s' "$1"
    ;;
  command_requires_project)
    printf 'This command must be run inside a configured project'
    ;;
  list_no_args)
    printf 'list takes no arguments'
    ;;
  list_global_project_header)
    printf '📁 %s' "$1"
    ;;
  list_global_worktree_entry)
    local marker="$1"
    local name="$2"
    local branch="$3"
    local hash="$4"
    local path="$5"
    printf '  %s %-13s %-18s %-8s  %s' "$marker" "$name" "$branch" "$hash" "$path"
    ;;
  main_no_args)
    printf 'main takes no arguments'
    ;;
  no_projects_configured)
    printf 'No projects are configured yet; run wt init inside a repository first'
    ;;
  path_requires_name)
    printf 'path requires exactly one worktree name'
    ;;
  worktree_not_found)
    printf 'worktree not found: %s' "$1"
    ;;
  add_requires_name)
    printf 'add requires a worktree name'
    ;;
  add_unknown_option)
    printf 'unknown option for add: %s' "$1"
    ;;
  unexpected_extra_argument)
    printf 'unexpected extra argument: %s' "$1"
    ;;
  invalid_worktree_name)
    printf 'invalid worktree name: %s (no /, \\, ~, dot segments, or whitespace)' "$1"
    ;;
  port_requires_numeric)
    printf 'port requires a numeric value between 1024 and 65535'
    ;;
  worktree_exists)
    printf 'worktree path already exists: %s' "$1"
    ;;
  config_list_no_args)
    printf 'config list takes no additional arguments'
    ;;
  config_list_empty)
    printf 'No stored config values found in %s (defaults in effect).' "$1"
    ;;
  config_get_requires_key)
    printf 'config get requires a key'
    ;;
  config_get_requires_exactly_one)
    printf 'config get requires exactly one key'
    ;;
  config_key_not_found)
    printf 'config key not found: %s' "$1"
    ;;
  config_unset_requires_key)
    printf 'config unset requires a key'
    ;;
  config_unset_requires_exactly_one)
    printf 'config unset requires exactly one key'
    ;;
  config_unknown_option)
    printf 'unknown config option: %s' "$1"
    ;;
  config_expect_key_or_value)
    printf 'config expects <key> or <key> <value>'
    ;;
  shell_hook_requires_shell)
    printf 'shell-hook requires a shell (bash or zsh)'
    ;;
  shell_hook_unsupported_shell)
    printf 'unsupported shell for shell-hook: %s (supported: bash, zsh)' "$1"
    ;;
  branch_requires_value)
    printf 'branch requires a value'
    ;;
  init_unknown_option)
    printf 'unknown option for init: %s' "$1"
    ;;
  init_no_positional)
    printf 'init takes no positional arguments'
    ;;
  init_forbid_home)
    printf 'wt init cannot target your home directory (%s)' "$1"
    ;;
  init_run_inside_git)
    printf 'run wt init inside a git repository'
    ;;
  remove_unknown_option)
    printf 'unknown option for remove: %s' "$1"
    ;;
  remove_accepts_at_most_one)
    printf 'remove accepts at most one worktree name'
    ;;
  cannot_remove_main)
    printf 'cannot remove the main worktree'
    ;;
  specify_worktree_or_inside)
    printf 'specify a worktree name or run from inside a worktree'
    ;;
  clean_no_args)
    printf 'clean takes no arguments'
    ;;
  invalid_language)
    printf 'unsupported language: %s (supported: en, zh)' "$1"
    ;;
  uninstall_auto_detected_shell)
    printf 'Auto-detected shell: %s' "$1"
    ;;
  uninstall_requires_shell_value)
    printf '--shell requires a value'
    ;;
  uninstall_requires_prefix_value)
    printf '--prefix requires a value'
    ;;
  uninstall_invalid_shell)
    printf 'Invalid shell type: %s (use zsh, bash, or none)' "$1"
    ;;
  uninstall_unknown_option)
    printf 'unknown option for uninstall: %s' "$1"
    ;;
  uninstall_no_positional)
    printf 'uninstall takes no positional arguments'
    ;;
  uninstall_removed_binary)
    printf 'Removed wt from %s' "$1"
    ;;
  uninstall_binary_missing)
    printf 'wt not found at %s (already removed?)' "$1"
    ;;
  uninstall_removed_messages)
    printf 'Removed wt messages from %s' "$1"
    ;;
  uninstall_shell_config_missing)
    printf 'Shell config file %s does not exist, skipping.' "$1"
    ;;
  uninstall_shell_hook_missing)
    printf 'No wt shell hook found in %s, skipping.' "$1"
    ;;
  uninstall_backup_created)
    printf 'Created backup: %s.backup.%s' "$1" "$2"
    ;;
  uninstall_shell_hook_removed)
    printf 'Removed wt shell hook from %s' "$1"
    ;;
  uninstall_unknown_shell_type)
    printf 'Warning: Unknown shell type %s, skipping shell cleanup' "$1"
    ;;
  uninstall_skip_shell_cleanup)
    printf 'Skipping shell configuration cleanup (use --shell zsh or --shell bash to clean)'
    ;;
  uninstall_complete)
    printf 'Uninstallation complete.'
    ;;
  uninstall_config_backup_created)
    printf 'Backed up wt config from %s to %s' "$1" "$2"
    ;;
  uninstall_worktrees_preserved)
    printf 'Note: Any existing worktrees were preserved'
    ;;
  reinstall_unknown_option)
    printf 'unknown option for reinstall: %s' "$1"
    ;;
  reinstall_no_positional)
    printf 'reinstall takes no positional arguments'
    ;;
  reinstall_requires_shell_value)
    printf '--shell requires a value'
    ;;
  reinstall_requires_prefix_value)
    printf '--prefix requires a value'
    ;;
  reinstall_script_missing)
    printf 'required script not found: %s' "$1"
    ;;
  reinstall_curl_required)
    printf 'curl is required to download reinstall helpers'
    ;;
  reinstall_fetch_remote_uninstall)
    printf 'Downloading uninstall.sh from %s' "$1"
    ;;
  reinstall_fetch_remote_install)
    printf 'Downloading install.sh from %s' "$1"
    ;;
  reinstall_fetch_failed)
    printf 'failed to download %s' "$1"
    ;;
  reinstall_running)
    printf 'Running %s' "$1"
    ;;
  reinstall_uninstall_failed)
    printf 'uninstall script failed: %s' "$1"
    ;;
  reinstall_install_failed)
    printf 'install script failed: %s' "$1"
    ;;
  reinstall_complete)
    printf '✅ Reinstall complete. Restart your shell if wt was running elsewhere.'
    ;;
  *)
    printf '%s' "$key"
    ;;
  esac
}

msg_zh() {
  local key="${1:-}"
  shift || true
  case "$key" in
  copy_env_file)
    printf '📄 复制 %s → %s' "$1" "$2"
    ;;
  copy_env_missing)
    printf '⚠️  源文件不存在，已跳过：%s' "$1"
    ;;
  command_not_found)
    printf '⚠️  未找到命令：%s，已跳过' "$1"
    ;;
  start_dev_port)
    printf '🚀 正在启动开发命令（端口 %s）' "$1"
    ;;
  start_dev_default)
    printf '🚀 正在启动开发命令'
    ;;
  start_dev_generic)
    printf '🚀 正在启动开发命令'
    ;;
  dev_started_port)
    printf '✅ 开发命令已就绪，端口 %s 已开始监听' "$1"
    ;;
  dev_started_default)
    printf '✅ 开发命令已启动'
    ;;
  dev_failed)
    printf '⚠️ 开发命令进程可能未正确启动 (PID: %s)，请检查 %s' "$1" "$2"
    ;;
  dev_timeout)
    printf '⚠️ 开发命令在 %s 秒内未能在端口 %s 就绪，请检查 %s' "$2" "$1" "$3"
    ;;
  dev_log_hint)
    printf '📝 开发命令日志：tail -f %s' "$1"
    ;;
  install_skipped_no_command)
    printf '⚙️  未配置安装命令，跳过依赖安装'
    ;;
  install_skipped_missing_lock)
    printf '⚠️  缺少 package-lock.json 或 npm-shrinkwrap.json，已跳过依赖安装（%s）' "$1"
    ;;
  install_detected)
    printf '🔍 自动检测到安装命令：%s' "$1"
    ;;
  serve_detected)
    printf '🔍 自动检测到开发命令：%s' "$1"
    ;;
  dev_command)
    printf '🚀 开发命令：%s' "$1"
    ;;
  dev_skipped_no_command)
    printf '⚙️  未配置开发命令，已跳过'
    ;;
  dev_skipped_no_port)
    printf '⚙️  未能从名称推导端口，已跳过开发命令'
    ;;
  auto_cd_pending)
    printf '💡 检测到 wt 自动切换目录尚未生效。尝试运行：%s' "$1"
    ;;
  auto_cd_retry)
    printf '   如果命令无效，请重新打开一个终端。'
    ;;
  auto_cd_disabled)
    printf '💡 检测到 wt 自动切换目录未启用。若希望直接跳转，可运行：%s' "$1"
    ;;
  auto_cd_reload)
    printf '   然后重新加载当前 shell（例如重新打开一个终端）。'
    ;;
  auto_cd_execute)
    printf '   然后执行：%s（或重新打开终端）。' "$1"
    ;;
  reserved_port)
    printf '⚠️  %s 是保留端口 (1-1023)，不会用于开发命令' "$1"
    ;;
  port_out_of_range)
    printf '⚠️  %s 超出有效端口范围 (65535)，将使用默认端口' "$1"
    ;;
  fallback_default_port)
    printf '⚠️  将使用默认端口 3000 启动开发命令'
    ;;
  dev_skipped_reserved_port)
    printf '⚙️  检测到 %s 为保留端口 (<1024)，已跳过开发命令' "$1"
    ;;
  creating_worktree)
    printf '🔧 创建 worktree: %s (分支 %s)' "$1" "$2"
    ;;
  add_branch_prefix_fallback)
    printf '⚠️  检测到仓库已存在分支 "%s"，本次将使用分支前缀 %s 创建 worktree\n   若需固定配置：wt config set add.branch-prefix %s' "$1" "$2" "$3"
    ;;
  add_branch_prefix_exhausted)
    printf 'wt add 未能找到可用的分支前缀（例如：%s）；请手动设置 add.branch-prefix 后重试。' "$1"
    ;;
  worktree_created)
    printf '✅ worktree 创建完成'
    ;;
  installing_dependencies)
    printf '📦 安装依赖 (%s)' "$1"
    ;;
  dev_skipped_config)
    printf '⚙️  根据配置已跳过开发命令'
    ;;
  worktree_ready)
    printf '✅ 新 worktree 就绪: %s' "$1"
    ;;
  init_set_project)
    printf '\n\033[94;1m%-11s\033[0m → \033[32m%s\033[0m\n' 'repo.path' "$1"
    ;;
  init_branch_option_deprecated)
    printf '  repo.branch 已移除；忽略传入的分支 "%s"\n' "$1"
    ;;
  init_slug_failed)
    printf '无法从当前仓库解析项目 slug'
    ;;
  init_slug_mismatch)
    printf '已存在的项目 %s 指向 %s（当前仓库：%s），操作已中止' "$1" "$2" "$3"
    ;;
  init_created_project)
    printf '\033[94;1m%-11s\033[0m → \033[32m%s\033[0m\n' 'config file' "$2"
    ;;
  init_done)
    printf 'wt init 已完成。\n'
    ;;
  lang_set_requires)
    printf 'wt lang set 需要一个参数（en 或 zh）'
    ;;
  lang_unknown_command)
    printf '未知 wt lang 命令：%s' "$1"
    ;;
  lang_prompt_select)
    printf '选择界面语言：'
    ;;
  lang_option_en_label)
    printf '英文 (English)'
    ;;
  lang_option_en_hint)
    printf 'English 界面'
    ;;
  lang_option_zh_label)
    printf '中文'
    ;;
  lang_option_zh_hint)
    printf '中文界面'
    ;;
  lang_option_reset_label)
    printf '重置为默认值'
    ;;
  lang_option_reset_hint)
    printf '恢复英文（默认）'
    ;;
  lang_set_success)
    printf '界面语言已切换为%s（%s）' "$1" "$2"
    ;;
  lang_reset_success)
    printf '界面语言已重置为%s（%s）' "$1" "$2"
    ;;
  lang_current)
    printf '当前界面语言：%s（%s）' "$1" "$2"
    ;;
  theme_set_requires)
    printf 'theme set 需要 <box|sage|archer>'
    ;;
  invalid_theme)
    printf '未知主题：%s（可选 box、sage 或 archer）' "$1"
    ;;
  theme_set_success)
    printf '列表主题已切换为 %s' "$2"
    ;;
  theme_reset_success)
    printf '列表主题已重置为 %s' "$2"
    ;;
  theme_current)
    printf '当前列表主题：%s' "$2"
    ;;
  theme_option_box_label)
    printf 'box'
    ;;
  theme_option_box_hint)
    printf 'wt list 使用方框标题'
    ;;
  theme_option_sage_label)
    printf 'sage'
    ;;
  theme_option_sage_hint)
    printf 'wt list 使用简洁标题（包含路径）'
    ;;
  theme_option_archer_label)
    printf 'archer'
    ;;
  theme_option_archer_hint)
    printf 'wt list 使用简洁标题（不显示路径）'
    ;;
  theme_option_reset_label)
    printf '重置为默认值'
    ;;
  theme_option_reset_hint)
    printf '恢复方框主题'
    ;;
  theme_prompt_select)
    printf '选择 wt list 输出的主题：'
    ;;
  theme_selection_cancelled)
    printf '已取消主题选择'
    ;;
  theme_unknown_command)
    printf '未知主题命令：%s' "$1"
    ;;
  theme_usage)
    cat << 'THEME_USAGE_ZH'
wt theme - 管理 worktree.sh 列表主题

交互式 (TTY):
  wt theme                 使用方向键选择主题

非交互式:
  wt theme get             输出当前主题代码
  wt theme set <box|sage|archer>  切换主题
  wt theme reset                 恢复默认主题（box）
  wt theme box|sage|archer       等同于 wt theme set
  wt theme help            显示本帮助
THEME_USAGE_ZH
    ;;
  lang_usage)
    cat << 'LANG_USAGE_ZH'
wt lang - 管理 worktree.sh 界面语言

交互式 (TTY):
  wt lang                  使用方向键选择语言

非交互式:
  wt lang get              输出当前语言代码
  wt lang set <en|zh>      切换语言
  wt lang reset            恢复默认语言（英文）
  wt lang en|zh            等同于 wt lang set
  wt lang help             显示本帮助
LANG_USAGE_ZH
    ;;
  help_usage)
    cat << 'HELP_USAGE_ZH'
wt help - 查看全局帮助或子命令帮助

用法:
  wt help
  wt help <command>

示例:
  wt help add
  wt help sync

提示:
  核心命令都支持 --help，例如：
  wt add --help
HELP_USAGE_ZH
    ;;
  list_usage)
    cat << 'LIST_USAGE_ZH'
wt list - 查看当前项目已登记的 worktree

用法:
  wt
  wt list
  wt list --help

说明:
  - 在已配置项目中，会显示主 worktree 及其兄弟 worktree。
  - 在未配置目录中，可先用 wt help 看命令，或进入仓库执行 wt init。
LIST_USAGE_ZH
    ;;
  main_usage)
    cat << 'MAIN_USAGE_ZH'
wt main - 输出主 worktree 路径

用法:
  wt main
  wt main --help

说明:
  - 安装 shell-hook 后，执行 wt main 会自动切回主仓库。
  - 未安装 shell-hook 时，会输出绝对路径，方便手动 cd。
MAIN_USAGE_ZH
    ;;
  path_usage)
    cat << 'PATH_USAGE_ZH'
wt path - 输出 worktree 路径而不切换目录

用法:
  wt path <name>
  wt path --help

示例:
  wt path 3000
  wt path ui9083
PATH_USAGE_ZH
    ;;
  add_usage)
    cat << 'ADD_USAGE_ZH'
wt add - 基于当前分支创建新的 worktree

用法:
  wt add <name>
  wt add --help

<name> 会同时决定：
  - worktree 路径后缀（例如 ../project.<name>）
  - 分支后缀（例如 feat/<name>）
  - 当名称为纯数字或以数字结尾时，对应 dev 命令的 PORT

端口规则:
  - wt add 9083      -> PORT=9083
  - wt add ui9083    -> worktree 名称为 ui9083，分支为 feat/ui9083，PORT=9083
  - 小于 1024 的端口视为保留端口，不会传给 dev 命令
  - 大于 65535 的端口会回退到默认 dev 端口行为

示例:
  wt add 3000
  wt add ui9083
  wt add feat-auth
ADD_USAGE_ZH
    ;;
  merge_usage)
    cat << 'MERGE_USAGE_ZH'
wt merge - 将指定 worktree 分支合并回当前主分支

用法:
  wt merge <name>
  wt merge --help

示例:
  wt merge 3000
  wt merge ui9083

说明:
  - 请在主 worktree 中、目标主分支上执行。
  - 主 worktree 和目标 worktree 都必须是干净状态。
MERGE_USAGE_ZH
    ;;
  sync_usage)
    cat << 'SYNC_USAGE_ZH'
wt sync - 将主 worktree 已暂存的改动应用到其他 worktree

用法:
  wt sync all
  wt sync <name> [name ...]
  wt sync --help

示例:
  wt sync all
  wt sync 3000 ui9083

说明:
  - sync 会读取当前主 worktree 已暂存的 diff。
  - 目标 worktree 在同步前必须保持干净。
SYNC_USAGE_ZH
    ;;
  remove_usage)
    cat << 'REMOVE_USAGE_ZH'
wt rm - 删除 worktree 及其功能分支

用法:
  wt rm [name ...]
  wt rm --help

示例:
  wt rm 3000
  wt rm ui9083
  wt rm          # 在 worktree 目录内执行时删除当前 worktree

说明:
  - 受保护分支或分支名不匹配时，会跳过删分支而不是强删。
  - 别名：wt remove
REMOVE_USAGE_ZH
    ;;
  clean_usage)
    cat << 'CLEAN_USAGE_ZH'
wt clean - 批量删除当前项目中的纯数字 worktree

用法:
  wt clean
  wt clean --help

说明:
  - 只匹配后缀为纯数字的 worktree，例如 3000、9083。
  - 不会删除 ui9083、feat-auth 这类带名字的 worktree。
CLEAN_USAGE_ZH
    ;;
  detach_usage)
    cat << 'DETACH_USAGE_ZH'
wt detach - 删除某个项目登记的全部 worktree

用法:
  wt detach [-y|--yes] [project-slug]
  wt detach --help

示例:
  wt detach
  wt detach -y
  wt detach my-project

说明:
  - 在项目工作区内执行时，默认使用当前项目 slug。
  - 在全局模式下，如果不传 slug，wt 可以交互式让你选择项目。
DETACH_USAGE_ZH
    ;;
  init_prompt_repo_path)
    printf 'wt 追踪的主仓库地址?'
    ;;
  init_prompt_copy_env)
    printf '是否自动拷贝环境变量?'
    ;;
  init_prompt_copy_env_files)
    printf '拷贝哪些环境变量文件?'
    ;;
  init_prompt_install_command)
    printf '安装依赖的命令?'
    ;;
  init_prompt_install_custom)
    printf '请输入自定义安装命令：'
    ;;
  init_install_option_npm_ci_hint)
    printf '依赖 package-lock.json'
    ;;
  init_install_option_npm_install_hint)
    printf '无需锁文件，速度较慢'
    ;;
  init_install_option_pnpm_install_hint)
    printf '需要 pnpm-lock.yaml'
    ;;
  init_install_option_yarn_install_hint)
    printf '需要 yarn.lock'
    ;;
  init_install_option_bun_install_hint)
    printf '需要 Bun'
    ;;
  init_install_option_uv_sync_hint)
    printf '适用于 uv 虚拟环境'
    ;;
  init_install_option_poetry_install_hint)
    printf '适用于 Poetry 项目'
    ;;
  init_install_option_pipenv_install_hint)
    printf '适用于 Pipenv 项目'
    ;;
  init_install_option_pdm_install_hint)
    printf '适用于 PDM 项目'
    ;;
  init_install_option_rye_install_hint)
    printf '适用于 Rye 项目'
    ;;
  init_install_option_hatch_install_hint)
    printf '适用于 Hatch 项目'
    ;;
  init_install_option_conda_hint)
    printf '适用于提供 Conda 环境文件的 Python 项目'
    ;;
  init_install_option_pip_create_venv_hint)
    printf '创建虚拟环境并安装依赖'
    ;;
  init_install_option_pip_requirements_hint)
    printf 'pip install -r requirements.txt'
    ;;
  init_install_option_skip_label)
    printf '不自动安装'
    ;;
  init_install_option_skip_hint)
    printf '跳过依赖安装步骤'
    ;;
  init_install_option_custom_label)
    printf '自定义命令'
    ;;
  init_install_option_custom_hint)
    printf '输入你自己的安装命令'
    ;;
  init_install_option_detected_hint)
    printf '根据仓库特征自动检测'
    ;;
  init_install_option_existing_hint)
    printf '沿用当前配置'
    ;;
  init_prompt_serve_command)
    printf '启动开发服务的命令?'
    ;;
  init_prompt_serve_custom)
    printf '请输入自定义启动命令：'
    ;;
  init_serve_option_npm_run_dev_hint)
    printf 'npm run dev（package.json scripts）'
    ;;
  init_serve_option_pnpm_dev_hint)
    printf 'pnpm dev（package.json scripts）'
    ;;
  init_serve_option_yarn_dev_hint)
    printf 'yarn dev（package.json scripts）'
    ;;
  init_serve_option_bun_dev_hint)
    printf 'bun dev（package.json scripts）'
    ;;
  init_serve_option_uv_run_hint)
    printf 'uv run（Python 开发服务）'
    ;;
  init_serve_option_poetry_run_hint)
    printf 'poetry run（自动处理虚拟环境）'
    ;;
  init_serve_option_pipenv_run_hint)
    printf 'pipenv run（自动处理虚拟环境）'
    ;;
  init_serve_option_pdm_run_hint)
    printf 'pdm run（自动处理虚拟环境）'
    ;;
  init_serve_option_rye_run_hint)
    printf 'rye run（自动处理虚拟环境）'
    ;;
  init_serve_option_hatch_run_hint)
    printf 'hatch run（自动处理虚拟环境）'
    ;;
  init_serve_option_conda_hint)
    printf 'conda run（使用 Conda 环境）'
    ;;
  init_serve_option_pip_venv_hint)
    printf '使用虚拟环境中的命令'
    ;;
  init_serve_option_manage_runserver_hint)
    printf 'Django manage.py runserver'
    ;;
  init_serve_option_python_app_hint)
    printf 'python app.py'
    ;;
  init_serve_option_skip_label)
    printf '不自动启动'
    ;;
  init_serve_option_skip_hint)
    printf '跳过自动启动开发服务'
    ;;
  init_serve_option_custom_label)
    printf '自定义命令'
    ;;
  init_serve_option_custom_hint)
    printf '输入你自己的启动命令'
    ;;
  init_serve_option_detected_hint)
    printf '根据仓库特征自动检测'
    ;;
  init_serve_option_existing_hint)
    printf '沿用当前配置'
    ;;
  init_prompt_serve_logging_path)
    printf '开发日志输出目录?（留空则禁用）'
    ;;
  init_prompt_branch_prefix)
    printf '首选 worktree 分支前缀?'
    ;;
  init_prompt_branch_custom)
    printf '请输入自定义分支前缀：'
    ;;
  init_branch_option_current_hint)
    printf '沿用当前配置'
    ;;
  init_branch_option_default_hint)
    printf '默认分支前缀（推荐）'
    ;;
  init_branch_option_alternative_hint)
    printf '常见备用前缀'
    ;;
  init_branch_option_skip_label)
    printf '保持现状'
    ;;
  init_branch_option_skip_hint)
    printf '不修改默认前缀'
    ;;
  init_branch_option_custom_label)
    printf '自定义前缀'
    ;;
  init_branch_option_custom_hint)
    printf '输入你自己的分支前缀'
    ;;
  aborted)
    printf '已取消'
    ;;
  removing_worktree)
    printf '🗑️  删除 worktree: %s' "$1"
    ;;
  removed_branch)
    printf '🗂️  已删除分支 %s' "$1"
    ;;
  worktree_removed)
    printf '✅ 已移除 worktree %s' "$1"
    ;;
  current_worktree_removed)
    printf '📁 当前 worktree 已移除，切换回主目录'
    ;;
  merge_requires_name)
    printf 'merge 需要指定 worktree 名称（例如 wt merge 123）'
    ;;
  merge_invalid_target)
    printf '解析得到 %s（worktree %s）→ %s（主工作区）；wt merge 预期特性分支，请检查 worktree 名称或分支前缀。' "$1" "$2" "$3"
    ;;
  merge_base_dirty)
    printf '主仓存在未提交修改，合并前请提交或暂存'
    ;;
  merge_branch_not_found)
    printf '未找到特性分支：%s' "$1"
    ;;
  merge_feat_dirty)
    printf 'worktree %s 存在未提交修改，合并前请提交或暂存' "$1"
    ;;
  merge_no_commits)
    printf '%s 相对于 %s 没有新的提交，已跳过合并' "$1" "$2"
    ;;
  merge_start)
    printf '🔀 正在将 %s 合并到 %s' "$1" "$2"
    ;;
  merge_conflict_abort)
    printf '⚠️ 合并冲突，请手动合并后自行/使用LLM解决冲突/使用LLM移植变更。'
    ;;
  merge_done)
    printf '✅ 合并完成: %s → %s' "$1" "$2"
    ;;
  merge_cleanup_hint)
    printf '🧹 如需清理请运行：wt rm %s' "$1"
    ;;
  project_branch_required)
    printf '主仓当前处于游离 HEAD，请先切换到具名分支后重试'
    ;;
  project_directory_required)
    printf '请在 %s 或其任意子目录运行该命令' "$1"
    ;;
  sync_requires_target)
    printf 'sync 需要传入 "all" 或至少一个 worktree 名称'
    ;;
  sync_invalid_all)
    printf 'sync 的 "all" 不能与其他名称同时使用'
    ;;
  sync_base_dirty)
    printf '主工作区存在未暂存或未追踪的改动，请先提交或暂存后再同步'
    ;;
  sync_skip_base)
    printf '⚙️  跳过主工作区（%s）' "$1"
    ;;
  sync_no_targets)
    printf '没有可同步的 worktree'
    ;;
  sync_no_staged)
    printf '没有可同步的暂存改动，请先执行 git add'
    ;;
  sync_patch_failed)
    printf '准备暂存差异失败，无法完成同步'
    ;;
  sync_target_dirty)
    printf 'worktree %s 不干净（%s），请先提交或暂存后再同步' "$1" "$2"
    ;;
  sync_apply_failed)
    printf '⚠️  向 %s 同步暂存改动失败，请手动处理' "$1"
    ;;
  sync_apply_start)
    printf '📤 正在向 %s 同步暂存改动' "$1"
    ;;
  sync_apply_done)
    printf '✅ 已同步 %s' "$1"
    ;;
  sync_done)
    printf '✅ 同步完成（更新了 %s 个 worktree）' "$1"
    ;;
  cleaning_worktree)
    printf '🧹 清理 worktree: %s' "$1"
    ;;
  cleaned_count)
    printf '✅ 已清理 %s 个 worktree' "$1"
    ;;
  cleaned_none)
    printf '✅ 没有符合条件的数字 worktree'
    ;;
  clean_switch_back)
    printf '📁 当前 worktree 已清理，切换回主目录'
    ;;
  clean_confirm_prompt)
    printf '是否删除项目 %s 的数字 worktree %s（%s）？[Y/n]' "$2" "$1" "$3"
    ;;
  remove_confirm_prompt)
    printf '删除 worktree %s？[Y/n]' "$1"
    ;;
  remove_confirm_prompt_global)
    printf '是否删除项目 %s 中的 %s（%s）？[Y/n]' "$2" "$1" "$3"
    ;;
  remove_failed)
    printf '删除 %s 失败' "$1"
    ;;
  remove_branch_skip_protected)
    printf '⚠️  跳过删除分支：%s 当前挂着受保护分支 %s（期望精确匹配 %s）' "$1" "$2" "$3"
    ;;
  remove_branch_skip_mismatch)
    printf '⚠️  跳过删除分支：%s 当前分支 %s 与期望分支 %s 不完全一致' "$1" "$2" "$3"
    ;;
  remove_branch_skip_missing)
    printf '⚠️  跳过删除分支：无法确认 %s 当前分支（期望精确匹配 %s）' "$1" "$2"
    ;;
  detach_prompt_worktree)
    printf '移除工作树 %s？[Y/n]' "$1"
    ;;
  detach_abort_user)
    printf '用户已取消 detach 操作'
    ;;
  detach_remove_failed)
    printf '移除 %s 失败：%s' "$1" "$2"
    ;;
  detach_summary_removed)
    printf '已移除 %s 个工作树' "$1"
    ;;
  detach_summary_failed)
    printf '移除失败：%s（%s）' "$1" "$2"
    ;;
  detach_summary_skipped)
    printf '已跳过 %s 个剩余工作树' "$1"
    ;;
  detach_prompt_project)
    printf '解除项目 %s 的注册？[Y/n]' "$1"
    ;;
  detach_done)
    printf '✅ 已解除项目 %s 的注册' "$1"
    ;;
  detach_project_missing)
    printf '未找到项目 %s，未执行任何操作' "$1"
    ;;
  detach_no_projects)
    printf '当前没有已注册的项目，请先运行 wt init'
    ;;
  detach_unknown_option)
    printf 'detach 的未知参数：%s' "$1"
    ;;
  config_set_requires)
    printf 'config set 需要 <key> <value>'
    ;;
  temp_file_failed)
    printf '无法创建临时文件'
    ;;
  config_unset_requires)
    printf 'config unset 需要 <key>'
    ;;
  config_file_missing)
    printf '未找到配置文件: %s' "$1"
    ;;
  config_key_not_set)
    printf '配置项未设置: %s' "$1"
    ;;
  config_update_failed)
    printf '更新配置失败'
    ;;
  select_navigation_hint)
    printf '（使用 ↑/↓ 或 j/k 移动，Enter 确认，Ctrl+C 取消；也可直接输入数字跳转。）'
    ;;
  prompt_yes_label)
    printf 'Yes'
    ;;
  prompt_no_label)
    printf 'No'
    ;;
  prompt_choice_hint)
    printf '%s' '- 使用方向键选择，回车确认，Ctrl+C 取消。'
    ;;
  prompt_default_hint)
    printf '默认值（按回车保留）：%s' "$1"
    ;;
  prompt_empty_display)
    printf '（留空）'
    ;;
  select_project_prompt)
    printf '请选择项目：'
    ;;
  select_project_option)
    if [ -n "${3:-}" ]; then
      printf '  [%d] %s（%s）— %s' "$1" "$2" "$3" "$4"
    else
      printf '  [%d] %s — %s' "$1" "$2" "$4"
    fi
    ;;
  select_project_input)
    printf '输入编号 (1-%s)，或直接回车取消：' "$1"
    ;;
  select_project_invalid)
    printf '请输入 1-%s 之间的数字。' "$1"
    ;;
  select_worktree_prompt)
    printf '请选择匹配的 worktree：'
    ;;
  select_worktree_option)
    printf '  [%d] %s（项目 %s）— %s' "$1" "$2" "$3" "$4"
    ;;
  select_worktree_input)
    printf '输入编号 (1-%s)，或直接回车取消：' "$1"
    ;;
  select_worktree_invalid)
    printf '请输入 1-%s 之间的数字。' "$1"
    ;;
  git_required)
    printf '需要安装 git'
    ;;
  project_not_found)
    printf '未找到项目目录: %s' "$1"
    ;;
  project_dir_unset)
    printf 'wt 尚未初始化，请在仓库目录下运行 wt init'
    ;;
  project_selection_cancelled)
    printf '已取消项目选择'
    ;;
  project_path_missing)
    printf '项目 %s 缺少有效的 repo.path，请在该仓库内重新执行 wt init' "$1"
    ;;
  git_command_failed)
    printf 'git 命令在 %s 执行失败' "$1"
    ;;
  command_requires_project)
    printf '该命令需要在已初始化的项目目录中执行'
    ;;
  list_no_args)
    printf 'list 不接受参数'
    ;;
  list_global_project_header)
    printf '📁 %s' "$1"
    ;;
  list_global_worktree_entry)
    local marker="$1"
    local name="$2"
    local branch="$3"
    local hash="$4"
    local path="$5"
    printf '  %s %-13s %-18s %-8s  %s' "$marker" "$name" "$branch" "$hash" "$path"
    ;;
  main_no_args)
    printf 'main 不接受参数'
    ;;
  no_projects_configured)
    printf '尚未配置任何项目，请先在目标仓库执行 wt init'
    ;;
  path_requires_name)
    printf 'path 需要指定 worktree 名称'
    ;;
  worktree_not_found)
    printf '未找到 worktree: %s' "$1"
    ;;
  add_requires_name)
    printf 'add 需要指定 worktree 名称'
    ;;
  add_unknown_option)
    printf 'add 的未知选项: %s' "$1"
    ;;
  unexpected_extra_argument)
    printf '出现未预期的额外参数: %s' "$1"
    ;;
  invalid_worktree_name)
    printf '非法的 worktree 名称：%s（禁止包含 /、\\、~、路径点段或空白）' "$1"
    ;;
  port_requires_numeric)
    printf 'port 需要 1024-65535 之间的数值'
    ;;
  worktree_exists)
    printf 'worktree 路径已存在: %s' "$1"
    ;;
  config_list_no_args)
    printf 'config list 不接受额外参数'
    ;;
  config_list_empty)
    printf '未找到已保存的配置：%s（使用默认值）。' "$1"
    ;;
  config_get_requires_key)
    printf 'config get 需要提供 key'
    ;;
  config_get_requires_exactly_one)
    printf 'config get 需要且仅需要一个 key'
    ;;
  config_key_not_found)
    printf '未找到配置项: %s' "$1"
    ;;
  config_unset_requires_key)
    printf 'config unset 需要提供 key'
    ;;
  config_unset_requires_exactly_one)
    printf 'config unset 需要且仅需要一个 key'
    ;;
  config_unknown_option)
    printf '未知的 config 选项: %s' "$1"
    ;;
  config_expect_key_or_value)
    printf 'config 需要 <key> 或 <key> <value>'
    ;;
  shell_hook_requires_shell)
    printf 'shell-hook 需要指定 shell（bash 或 zsh）'
    ;;
  shell_hook_unsupported_shell)
    printf 'shell-hook 不支持的 shell: %s（仅支持 bash、zsh）' "$1"
    ;;
  branch_requires_value)
    printf 'branch 需要指定值'
    ;;
  init_unknown_option)
    printf 'init 的未知选项: %s' "$1"
    ;;
  init_no_positional)
    printf 'init 不接受位置参数'
    ;;
  init_forbid_home)
    printf '禁止在家目录运行 wt init（%s）' "$1"
    ;;
  init_run_inside_git)
    printf '请在 git 仓库中运行 wt init'
    ;;
  remove_unknown_option)
    printf 'remove 的未知选项: %s' "$1"
    ;;
  remove_accepts_at_most_one)
    printf 'remove 最多只接受一个 worktree 名称'
    ;;
  cannot_remove_main)
    printf '不能移除主 worktree'
    ;;
  specify_worktree_or_inside)
    printf '指定 worktree 名称或在 worktree 目录中运行'
    ;;
  clean_no_args)
    printf 'clean 不接受参数'
    ;;
  invalid_language)
    printf '不支持的语言: %s（支持 en、zh）' "$1"
    ;;
  uninstall_auto_detected_shell)
    printf '自动检测到 shell: %s' "$1"
    ;;
  uninstall_requires_shell_value)
    printf '--shell 需要一个值'
    ;;
  uninstall_requires_prefix_value)
    printf '--prefix 需要一个值'
    ;;
  uninstall_invalid_shell)
    printf '无效的 shell 类型: %s（可选 zsh、bash 或 none）' "$1"
    ;;
  uninstall_unknown_option)
    printf 'uninstall 未知选项: %s' "$1"
    ;;
  uninstall_no_positional)
    printf 'uninstall 不接受额外位置参数'
    ;;
  uninstall_removed_binary)
    printf '已从 %s 删除 wt' "$1"
    ;;
  uninstall_binary_missing)
    printf '在 %s 未找到 wt（可能已删除）' "$1"
    ;;
  uninstall_removed_messages)
    printf '已从 %s 删除 wt 消息文件' "$1"
    ;;
  uninstall_shell_config_missing)
    printf '未找到 shell 配置文件 %s，跳过。' "$1"
    ;;
  uninstall_shell_hook_missing)
    printf '未在 %s 找到 wt shell hook，跳过。' "$1"
    ;;
  uninstall_backup_created)
    printf '已创建备份: %s.backup.%s' "$1" "$2"
    ;;
  uninstall_shell_hook_removed)
    printf '已从 %s 移除 wt shell hook' "$1"
    ;;
  uninstall_unknown_shell_type)
    printf '警告: 未知 shell 类型 %s，跳过 shell 清理' "$1"
    ;;
  uninstall_skip_shell_cleanup)
    printf '跳过 shell 配置清理（使用 --shell zsh 或 --shell bash 可执行清理）'
    ;;
  uninstall_complete)
    printf '卸载完成。'
    ;;
  uninstall_config_backup_created)
    printf '已将 wt 配置从 %s 备份到 %s' "$1" "$2"
    ;;
  uninstall_worktrees_preserved)
    printf '注意: 已创建的 worktree 不会删除'
    ;;
  reinstall_unknown_option)
    printf 'reinstall 未知选项: %s' "$1"
    ;;
  reinstall_no_positional)
    printf 'reinstall 不接受位置参数'
    ;;
  reinstall_requires_shell_value)
    printf '--shell 需要一个值'
    ;;
  reinstall_requires_prefix_value)
    printf '--prefix 需要一个值'
    ;;
  reinstall_script_missing)
    printf '未找到所需脚本: %s' "$1"
    ;;
  reinstall_curl_required)
    printf '下载重新安装脚本需要 curl'
    ;;
  reinstall_fetch_remote_uninstall)
    printf '正在从 %s 下载 uninstall.sh' "$1"
    ;;
  reinstall_fetch_remote_install)
    printf '正在从 %s 下载 install.sh' "$1"
    ;;
  reinstall_fetch_failed)
    printf '无法下载 %s' "$1"
    ;;
  reinstall_running)
    printf '正在执行 %s' "$1"
    ;;
  reinstall_uninstall_failed)
    printf 'uninstall.sh 执行失败: %s' "$1"
    ;;
  reinstall_install_failed)
    printf 'install.sh 执行失败: %s' "$1"
    ;;
  reinstall_complete)
    printf '✅ 重新安装完成。如在其它终端运行 wt，请重启终端。'
    ;;
  *)
    printf '%s' "$key"
    ;;
  esac
}
