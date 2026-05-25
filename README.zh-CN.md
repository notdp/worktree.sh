# worktree.sh

**零摩擦的 git worktree 管理器，为并行功能开发而生。**

[English](README.md) • [日本語](README.ja.md)

## worktree.sh 是什么？

worktree.sh 自动化了设置 git worktree 的繁琐步骤。通过一条命令，它就能为 Codex、Claude Code 等编码 AI 创建隔离的开发沙盒——包含分支、环境文件、依赖项和运行中的开发服务器。杜绝上下文污染。

### 完美适用于

- **AI 驱动开发** — 为 Codex 和 Claude Code 提供隔离沙盒
- **并行开发** — 多功能并行无需切换分支
- **快速实验** — 安全的一次性环境
- **代码审查** — 审查 PR 不中断主线工作

## 快速预览

![CLI overview](asset/worktree.sh.screenshot-1.png)

## 快速开始

### 安装

```bash
curl -fsSL https://raw.githubusercontent.com/notdp/worktree.sh/main/install.sh | bash
```

### 基本工作流

```bash
# 1. 初始化项目（在主仓库中运行）
wt init

# 2. 为功能开发创建 worktree
wt add 3000
# 这会自动：
# - 在 ../project.3000 创建 worktree
# - 创建分支 feat/3000
# - 复制 .env 文件
# - 安装依赖
# - 在端口 3000 上启动开发服务器

# 名称以数字结尾时，也会把这些数字当作 dev PORT
wt add ui9083
# - 创建分支 feat/ui9083
# - 以 PORT=9083 启动配置好的 dev 命令

# 3. 在 worktree 之间导航
wt 3000    # 跳转到功能 worktree
wt main    # 返回主仓库

# 4. 准备就绪时合并（从主 worktree）
wt merge 3000

# 5. 清理
wt rm 3000
```

## 核心功能

- **一键设置** — `wt add 3000` 创建 worktree、分支，复制环境文件，安装依赖，并在端口 3000 上启动开发服务器
- **即时导航** — 使用 `wt 3000` 或 `wt main` 在 worktree 之间跳转，无需记忆路径
- **智能同步** — 使用 `wt sync all` 将暂存的更改从主分支传播到多个 worktree
- **安全清理** — 使用 `wt rm` 同时删除 worktree 和分支，使用 `wt clean` 批量清理
- **完全可配置** — 按项目控制分支前缀、自动安装、开发服务器行为

## 命令

### 核心命令

| 命令              | 描述                       | 示例            |
| ----------------- | -------------------------- | --------------- |
| `wt init`         | 将当前仓库初始化为默认项目 | `wt init`       |
| `wt add <name>`   | 创建完全配置的 worktree    | `wt add 3000`   |
| `wt <name>`       | 导航到 worktree            | `wt 3000`       |
| `wt main`         | 返回主仓库                 | `wt main`       |
| `wt list` (`wt`)  | 显示所有 worktree          | `wt list`       |
| `wt merge <name>` | 将功能分支合并回来         | `wt merge 3000` |

### 同步

| 命令                 | 描述                            | 示例                |
| -------------------- | ------------------------------- | ------------------- |
| `wt sync all`        | 将暂存的更改同步到所有 worktree | `wt sync all`       |
| `wt sync <names...>` | 同步到特定 worktree             | `wt sync 3000 3001` |

### 清理

| 命令              | 描述                  | 示例                            |
| ----------------- | --------------------- | ------------------------------- |
| `wt rm [name...]` | 删除 worktree         | `wt rm 3000` 或 `wt rm`（当前） |
| `wt clean`        | 批量删除数字 worktree | `wt clean`                      |
| `wt detach [-y]`  | 删除所有项目 worktree | `wt detach -y`                  |

### 配置

| 命令           | 描述                                           | 示例               |
| -------------- | ---------------------------------------------- | ------------------ |
| `wt config`    | 查看/修改项目设置                              | `wt config list`   |
| `wt lang`      | 设置 CLI 语言（en/zh）                         | `wt lang set zh`   |
| `wt theme`     | 切换 `wt list` 主题（`box`\|`sage`\|`archer`） | `wt theme set box` |
| `wt help`      | 显示命令参考                                   | `wt help`          |
| `wt help <command>` | 显示子命令帮助                           | `wt help add`      |
| `wt reinstall` | 更新到最新版本                                 | `wt reinstall`     |
| `wt uninstall` | 删除 worktree.sh                               | `wt uninstall`     |

## Help 与命名规则

- 所有核心命令都支持 `wt <command> --help`，而 `wt help <command>` 是等价的长写法。
- `wt add <name>` 会把名称末尾的数字当作 dev `PORT`。例如 `wt add ui9083` 会保留 worktree 名称 `ui9083`、创建分支 `feat/ui9083`，并以 `PORT=9083` 启动已配置的 dev 命令。

## 高级功能

### 跨 Worktree 广播更改

将未提交的更改从主分支同时传播到多个功能分支：

```bash
# 在主 worktree 中
git add file1.js file2.js    # 暂存更改
wt sync all                  # 同步到所有 worktree
# 或同步到特定的
wt sync 3000 3001
```

> 注意：目标 worktree 必须具有干净状态

### 自定义配置

```bash
# 禁用自动开发服务器
wt config set add.serve-dev.enabled false

# 启动脚本较慢时，延长端口就绪等待时间
wt config set add.serve-dev.ready-timeout 120

# 对启动器脚本保留一个短暂的就绪后观察窗口
wt config set add.serve-dev.settle-timeout 8

# 更改分支前缀
wt config set add.branch-prefix "feature/"

# 查看所有设置
wt config list
```

配置按项目存储在 `~/.worktree.sh/projects/<slug>/config.kv` 中。

- `add.serve-dev.ready-timeout` 控制 `wt add` 等待目标端口开始监听的最长秒数。
- `add.serve-dev.settle-timeout` 会在端口就绪后再短暂观察一段时间，避免 `start-smart.sh` 这类包装启动脚本被误判为失败。

## 使用场景

### 多开 UI 抽卡

```bash
wt add ui-v1    # 第一版 UI 方案
wt add ui-v2    # 备选设计
wt add ui-v3    # 第三种尝试
# 并行对比多个实现
```

### 并行代码审查

```bash
wt add review-pr-123    # 审查 PR #123
wt add review-pr-456    # 审查 PR #456
wt add review-pr-789    # 审查 PR #789
# 同时处理多个 PR 审查，无需切换上下文
```

### 并行功能开发

```bash
wt add feat-auth        # 认证功能
wt add feat-payment     # 支付集成
wt add feat-dashboard   # 仪表板重设计
# 并行开发多个功能
```

## 安装详情

### 安装内容

- 二进制文件：`~/.local/bin/wt`
- 配置：`~/.worktree.sh/`
- Shell 钩子：添加到 `~/.bashrc` 或 `~/.zshrc`

### 要求

- Bash 3.0+
- Git 2.17+（worktree 支持）
- macOS 或 Linux

### 更新

```bash
wt reinstall    # 更新到最新版本
```

### 卸载

```bash
wt uninstall
```

或使用卸载脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/notdp/worktree.sh/main/uninstall.sh | bash
```

---

**停止在分支间折腾。开始交付功能。**

worktree.sh 让你的终端保持同步，让你专注于代码，而非配置。
