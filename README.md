# worktree.sh

**Zero-friction git worktree manager for parallel feature development.**

[中文](README.zh-CN.md) • [日本語](README.ja.md)

## What is worktree.sh?

worktree.sh automates the tedious setup of git worktrees. With a single command, it creates isolated development sandboxes for coding agents like Codex and Claude Code—complete with branches, environment files, dependencies, and running dev servers. No context pollution.

### Perfect For

- **AI-Powered Development** — Isolated sandboxes for Codex and Claude Code
- **Parallel Development** — Multiple features without branch switching
- **Quick Experiments** — Safe disposable environments
- **Code Reviews** — Review PRs without interrupting main work

## Quick Look

![CLI overview](asset/worktree.sh.screenshot-1.png)

## Quick Start

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/notdp/worktree.sh/main/install.sh | bash
```

### Basic Workflow

```bash
# 1. Initialize project (run in your main repo)
wt init

# 2. Create a worktree for feature development
wt add 3000
# This automatically:
# - Creates worktree at ../project.3000
# - Creates branch feat/3000
# - Copies .env files
# - Installs dependencies
# - Starts dev server on port 3000

# Names with trailing digits also set the dev PORT
wt add ui9083
# - Creates branch feat/ui9083
# - Starts the configured dev command with PORT=9083

# 3. Navigate between worktrees
wt 3000    # Jump to feature worktree
wt main    # Return to main repository

# 4. Merge when ready (from main worktree)
wt merge 3000

# 5. Clean up
wt rm 3000
```

## Core Features

- **One-Command Setup** — `wt add 3000` creates worktree, branch, copies env files, installs deps, and starts dev server on port 3000
- **Instant Navigation** — Jump between worktrees with `wt 3000` or `wt main`, no path memorization needed
- **Smart Syncing** — Propagate staged changes from main to multiple worktrees with `wt sync all`
- **Safe Cleanup** — Remove worktrees and branches together with `wt rm`, batch-clean with `wt clean`
- **Fully Configurable** — Control branch prefixes, auto-install, dev server behavior per project

## Commands

### Core Commands

| Command           | Description                                | Example         |
| ----------------- | ------------------------------------------ | --------------- |
| `wt init`         | Initialize current repo as default project | `wt init`       |
| `wt add <name>`   | Create fully configured worktree           | `wt add 3000`   |
| `wt <name>`       | Navigate to worktree                       | `wt 3000`       |
| `wt main`         | Return to main repository                  | `wt main`       |
| `wt list` (`wt`)  | Show all worktrees                         | `wt list`       |
| `wt merge <name>` | Merge feature branch back                  | `wt merge 3000` |

### Synchronization

| Command              | Description                          | Example             |
| -------------------- | ------------------------------------ | ------------------- |
| `wt sync all`        | Sync staged changes to all worktrees | `wt sync all`       |
| `wt sync <names...>` | Sync to specific worktrees           | `wt sync 3000 3001` |

### Cleanup

| Command           | Description                    | Example                           |
| ----------------- | ------------------------------ | --------------------------------- |
| `wt rm [name...]` | Remove worktree(s)             | `wt rm 3000` or `wt rm` (current) |
| `wt clean`        | Batch remove numeric worktrees | `wt clean`                        |
| `wt detach [-y]`  | Remove all project worktrees   | `wt detach -y`                    |

### Configuration

| Command        | Description                  | Example          |
| -------------- | ---------------------------- | ---------------- |
| `wt config`    | View/modify project settings | `wt config list` |
| `wt lang`      | Set CLI language (en/zh)     | `wt lang set zh` |
| `wt theme`     | Switch `wt list` theme (`box`\|`sage`\|`archer`) | `wt theme set box` |
| `wt help`      | Show command reference       | `wt help`        |
| `wt help <command>` | Show subcommand help     | `wt help add`    |
| `wt reinstall` | Update to latest version     | `wt reinstall`   |
| `wt uninstall` | Remove worktree.sh           | `wt uninstall`   |

## Help and Naming Rules

- Every core command supports `wt <command> --help`, and `wt help <command>` is the equivalent long form.
- `wt add <name>` uses trailing digits as the dev `PORT`. For example, `wt add ui9083` keeps the worktree name `ui9083`, creates branch `feat/ui9083`, and runs the configured dev command with `PORT=9083`.

## Advanced Features

### Broadcasting Changes Across Worktrees

Propagate uncommitted changes from main to multiple feature branches simultaneously:

```bash
# In main worktree
git add file1.js file2.js    # Stage changes
wt sync all                  # Sync to all worktrees
# Or sync to specific ones
wt sync 3000 3001
```

> Note: Target worktrees must have clean status

### Custom Configuration

```bash
# Disable auto dev server
wt config set add.serve-dev.enabled false

# Wait longer for a slow startup script before reporting success
wt config set add.serve-dev.ready-timeout 120

# Keep a short post-ready observation window for launcher scripts
wt config set add.serve-dev.settle-timeout 8

# Change branch prefix
wt config set add.branch-prefix "feature/"

# View all settings
wt config list
```

Configuration is stored per-project in `~/.worktree.sh/projects/<slug>/config.kv`.

- `add.serve-dev.ready-timeout` controls how long `wt add` waits for the inferred port to start listening.
- `add.serve-dev.settle-timeout` keeps watching briefly after readiness so wrapper scripts like `start-smart.sh` can exit without causing a false failure.

## Use Cases

### Multiple UI Iterations

```bash
wt add ui-v1    # First UI approach
wt add ui-v2    # Alternative design
wt add ui-v3    # Third variation
# Compare implementations side by side
```

### Parallel Code Reviews

```bash
wt add review-pr-123    # Review PR #123
wt add review-pr-456    # Review PR #456
wt add review-pr-789    # Review PR #789
# Handle multiple reviews without context switching
```

### Concurrent Feature Development

```bash
wt add feat-auth        # Authentication feature
wt add feat-payment     # Payment integration
wt add feat-dashboard   # Dashboard redesign
# Develop multiple features in parallel
```

## Installation Details

### What Gets Installed

- Binary: `~/.local/bin/wt`
- Config: `~/.worktree.sh/`
- Shell hooks: Added to `~/.bashrc` or `~/.zshrc`

### Requirements

- Bash 3.0+
- Git 2.17+ (worktree support)
- macOS or Linux

### Updating

```bash
wt reinstall    # Update to latest version
```

### Uninstalling

```bash
wt uninstall
```

Or use the uninstall script:

```bash
curl -fsSL https://raw.githubusercontent.com/notdp/worktree.sh/main/uninstall.sh | bash
```

---

**Stop juggling branches. Start shipping features.**

worktree.sh keeps your terminals synchronized and your focus on code, not configuration.
