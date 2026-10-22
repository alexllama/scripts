# git-watch

Nightly git repo monitor for $HOME. Discovers all git repos under $HOME using `fd`, explicitly handles bare repo at `$HOME/.cfg` with worktree `$HOME`. For each repo checks: dirty state, fetches upstream (with timeout), ahead/behind, SSH/HTTPS protocol. Reports all errors (including SSH/auth failures). 

## Files
- `git-watch` - Main script
- `systemd/git-watch.service` - systemd user service
- `systemd/git-watch.timer` - systemd user timer (03:00 with jitter)
- Config: `~/.config/git-watch/config` (bare repo entries)
- Env (optional): `~/.config/git-watch/env` (e.g. `SSH_AUTH_SOCK`)
- Reports: `~/.local/state/git-watch/last-report.md` (overwritten each run, no history)
- Log: `~/.local/state/git-watch/git-watch.log` (overwritten each run, no history)

## SSH Agent
You have ssh-agent with a passphrase. The timer runs outside your terminal session so it won't inherit `SSH_AUTH_SOCK`. If your key is encrypted and agent isn't available to the service, SSH fetches will fail and be reported as errors.

To make it work unattended, have your shell write the socket on login. For example in `~/.bashrc`/`~/.zshrc`:
```bash
if [ -n "$SSH_AUTH_SOCK" ]; then
  echo "SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.config/git-watch/env
  chmod 600 ~/.config/git-watch/env
fi
```
Or use `keychain`/a user ssh-agent service. The service also sources `~/.config/git-watch/env` if present.

## Installation
```bash
mkdir -p ~/.config/systemd/user
cp /home/alex/dev/scripts/git-watch/systemd/* ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now git-watch.timer
```

## Manual run
```bash
~/.local/bin/git-watch
# or
/home/alex/dev/scripts/git-watch/git-watch
```

View report: `cat ~/.local/state/git-watch/last-report.md` or open in editor.
