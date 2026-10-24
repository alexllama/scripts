# git-watch

Monitors all git repositories under `$HOME` nightly (and on demand). Discovers repos automatically with `fd`, explicitly tracks your bare dotfiles repo at `$HOME/.cfg` with worktree `$HOME`, reports dirty files and sync state with upstream, and alerts you via notification with a full report.

The folder also contains `git-updater`, the backend for updating repos in place (no `cd` required), intended to power an Omarchy plugin UI.

## What it does

For each repo found under `$HOME`:
1. **Discovery** - Uses `fd` to find `.git` directories/files (pruned to avoid node_modules, .cache, containers, cargo registry, etc.). Also reads explicit bare entries from `~/.config/git-watch/config` (includes `$HOME/.cfg`).
2. **Protocol detection** - Checks `origin` remote URL to classify as `ssh` (`git@...` or `ssh://`), `https` (`https://`), `other`, or `none`. Helps you see which repos still use HTTPS vs SSH.
3. **Branch & upstream** - Identifies current branch and its upstream tracking branch (`@{u}`).
4. **Local changes (dirty)** - Runs `git status --porcelain`. Counts modified/staged/untracked files. These are "unchecked code" that needs to be committed.
5. **Fetch from upstream** - Runs `git fetch --quiet --all` with a 300s timeout. Captures all errors (including SSH/auth failures, timeouts, network issues).
6. **Ahead/Behind** - After fetch, compares `HEAD` with upstream via `git rev-list`. Shows `+ahead/-behind` relative to upstream.
7. **Reporting** - Writes full report to `~/.local/state/git-watch/last-report.md` (overwritten each run - no history kept). Dirty/behind/error repos appear first, clean repos at the end. Notification shows summary and report path.

## Report structure

- **Needs Attention (Dirty / Behind / Errors)** - Repos with uncommitted changes, commits behind upstream, or errors during checks. Shows full details per repo.
- **Clean (No Action Needed)** - Repos up to date with no local changes and no errors.
- **Totals** - Summary counts

## Understanding the status

| Column | Meaning |
|--------|---------|
| Repo | Path to repo/worktree |
| Type | `NORMAL` or `BARE` |
| Proto | `ssh`, `https`, `other`, or `none` |
| Branch | Current branch name |
| Upstream | Upstream tracking branch or `none`/`unknown` |
| Dirty | Number of uncommitted changes (from `git status --porcelain`) |
| Ahead/Behind | `+N / -M` means N commits ahead of upstream, M commits behind upstream |
| Errors | `YES` if any errors occurred during checks |

### Common cases

#### Dirty (unchecked code)
You have local modifications not committed. 
**Resolve:**
```bash
cd /path/to/repo
git add -A
git commit -m "Your commit message"
git push
```

#### Behind (need to pull)
`+0/-N` means upstream has N commits you don't have locally.
**Resolve:**
```bash
cd /path/to/repo
git pull
```
If you have local commits too, consider `git pull --rebase` or merge as appropriate.

#### Ahead (need to push)
`+N/-0` means you have N commits not pushed to upstream.
**Resolve:**
```bash
cd /path/to/repo
git push
```

#### Ahead and behind (diverged)
`+N/-M` means both sides have unique commits.
**Resolve:**
```bash
cd /path/to/repo
git pull --rebase  # rebase your commits on top of upstream
# or
git pull  # merge
git push
```

#### No upstream configured
Upstream shows `none`. The repo isn't tracking a remote branch.
**Resolve:**
```bash
cd /path/to/repo
git branch -u origin/<branch>  # or set upstream
# or
git push -u origin <branch>
```

#### Detached HEAD
If branch shows `HEAD` or weird state, you're in detached HEAD. Check out a branch.
**Resolve:**
```bash
cd /path/to/repo
git checkout main  # or your branch
```

#### Errors / SSH failures
Errors section will show details. Common issues:
- **SSH auth failures** (`Permission denied (publickey)`) - SSH key not available to the script. Your ssh-agent has a passphrase and may not be available in the timer's environment.
- **HTTPS auth** - Credential helper may not be unlocked in non-interactive session.
- **Timeouts** - Network issues or slow remotes.
- **No remote** - Repo has no `origin` configured.

**For SSH (preferred):**
1. Write your SSH_AUTH_SOCK to the env file on login. Add to `~/.bashrc`/`~/.zshrc`:
```bash
if [ -n "$SSH_AUTH_SOCK" ]; then
  echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.config/git-watch/env
  chmod 600 ~/.config/git-watch/env
fi
```
2. Or use a user ssh-agent service, or `keychain`.
3. Alternatively use `ssh-add` to load keys and ensure agent persists.

**For HTTPS:** Use a credential helper that works non-interactively, or switch to SSH.

**Network issues:** The script uses 300s timeout and will report timeouts as errors.

## JSON output (for UIs)

`git-watch --json` emits the same discovery/status data as structured JSON on stdout, without writing the report or sending a notification. This is the machine-readable backend for `git-updater` and any future plugin UI.

```json
{
  "timestamp": "2026-10-23T08:10:53-04:00",
  "summary": {
    "repos_checked": 116,
    "dirty_files": 19,
    "behind_commits": 618,
    "repos_with_errors": 45
  },
  "repos": [
    {
      "path": "/home/alex/.config/omarchy/themes/aura",
      "type": "NORMAL",
      "gitdir": "/home/alex/.config/omarchy/themes/aura",
      "worktree": "",
      "protocol": "https",
      "branch": "main",
      "upstream": "origin/main",
      "dirty": 0,
      "ahead": 0,
      "behind": 1,
      "errors": false,
      "error_messages": [],
      "remote": "https://github.com/bjarneo/omarchy-aura-theme",
      "dirty_files": []
    }
  ]
}
```

Fields: `type` is `NORMAL` or `BARE`; `dirty` is a file count; `ahead`/`behind` are commit counts relative to `upstream`; `dirty_files` is the raw `git status --porcelain` lines.

## git-updater

Updates repos without navigating to them. It reuses `git-watch --json` for discovery/status and uses `git -C` for normal repos and `GIT_DIR`/`GIT_WORK_TREE` for bare repos.

```bash
git-updater list                 # status of every repo
git-updater refresh              # re-run discovery/fetch, refresh cache
git-updater update <path>        # update one repo (ff-only)
git-updater update-all           # update every clean, behind repo (ff-only)
```

Safety behavior:
- Repos with uncommitted changes are **skipped** (never auto-stashed or overwritten).
- Detached `HEAD` repos are **skipped** (e.g. some LazyVim plugins).
- Repos with no upstream are **skipped**.
- `--ff-only` is always used: if a repo has diverged, the pull fails instead of creating a merge commit. Resolve diverged repos manually.
- Timeouts (300s) prevent a slow remote from hanging the whole run.

The status is cached in `/tmp/git-updater-cache.json`; run `git-updater refresh` after updates to get fresh numbers.

## Files

- Script: `/home/alex/dev/scripts/git-watch/git-watch` (also symlinked to `~/.local/bin/git-watch`)
- Updater: `/home/alex/dev/scripts/git-watch/git-updater` (also symlinked to `~/.local/bin/git-updater`)
- Config: `~/.config/git-watch/config` - lists bare repos (format: `bare:<gitdir>:<worktree>`)
- Env (optional): `~/.config/git-watch/env` - for `SSH_AUTH_SOCK` etc.
- Report: `~/.local/state/git-watch/last-report.md` (overwritten each run, no history)
- Log: `~/.local/state/git-watch/git-watch.log` (overwritten each run, no history)
- Systemd: `~/.config/systemd/user/git-watch.{service,timer}`

## Usage

### Manual run
```bash
git-watch
# or
/home/alex/dev/scripts/git-watch/git-watch
```

### View report
```bash
cat ~/.local/state/git-watch/last-report.md
# or open in micro
micro ~/.local/state/git-watch/last-report.md
```

### Enable automatic nightly runs
Already enabled:
```bash
systemctl --user status git-watch.timer
```

Runs nightly at ~03:00 with 15m jitter. Timer is persistent.

## Notes

- Constrained to `$HOME` only (won't scan outside)
- Handles bare repos with worktrees (like `$HOME/.cfg` → worktree `$HOME`)
- Uses `fd` for discovery, excludes noisy directories
- All errors are reported explicitly
- Report is rebuilt fresh each run (no log bloat/history)
- Works on older systems, minimal dependencies
---

## Rofi UI (stage 3)

```bash
git-update-rofi
```

Menu: [UPDATE] pull clean behind repos, [UPDATE-ALL] pull all clean behind, [REFRESH], [REPORT] open full report, [OK]/[DIRTY]/[ERROR] for status. Uses git-updater under the hood.
Bind to a keybind in Hyprland/Omarchy for quick access.
