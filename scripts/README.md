# scripts/

Operator-side helpers for go-jupyter. The script in this directory is
also invoked by cloud-init on the deployed instance — but it can be run
locally on a laptop for ad-hoc inspection without any project venv.

## extract_github_users.py

Reads a `users.yaml` file from `geneontology/go-site/metadata/` and
prints GitHub usernames (one per line, lowercased, sorted, deduplicated)
suitable for use as a JupyterHub `allowed_users` allowlist.

Usage:

```sh
# Ad-hoc inspection: who would the OAuth allowlist contain right now?
scripts/extract_github_users.py ../go-site/metadata/users.yaml | head
scripts/extract_github_users.py ../go-site/metadata/users.yaml | wc -l

# Pipe into a file for testing or one-off use:
scripts/extract_github_users.py ../go-site/metadata/users.yaml > /tmp/allowlist.txt
```

The script is self-bootstrapping via PEP 723 inline metadata: as long as
you have `uv` installed, running it directly (or via `uv run`) will
install `pyyaml` into a transient environment on first invocation. No
project virtualenv needed.

GitHub names are lowercased and validated against the same loose POSIX
pattern that `jupyterhub_config.py`'s `pre_spawn_hook` enforces, so the
emitted list will not contain anything the spawner would reject. Rejected
entries are printed to stderr with a reason.

## Where the allowlist actually lives on a deployed instance

**You do not need to run this script as part of any deployment workflow.**
Cloud-init invokes it automatically at boot:

1. `curl https://raw.githubusercontent.com/geneontology/go-site/master/metadata/users.yaml`
2. `extract_github_users.py /tmp/go-site-users.yaml > /etc/jupyterhub/github_allowed_users.txt`
3. `jupyterhub_config.py` reads `/etc/jupyterhub/github_allowed_users.txt`
   at hub startup and feeds it to `GitHubOAuthenticator.allowed_users`.

So **every fresh `terraform apply` automatically picks up the current
state of `users.yaml`** with no operator action. To refresh on a running
deployment without replacing the instance, use the `go-jupyter-refresh-user`
helper in this directory (installed to PATH by cloud-init).

A cron-based refresh on the running box (a systemd timer running the
same fetch + extractor + `systemctl reload jupyterhub`) is a Phase 2
once newcomer latency between users.yaml updates and people being able
to log in starts to bite. Not yet implemented.

## go-jupyter-sync-skills vs go-jupyter-refresh-user — which delivers what

| Template file | Reaches existing homes via | When |
|---|---|---|
| skills from `skill-sources.txt` (go-skills, …) | `go-jupyter-link-skills <user>` — a clone per source in the home, links in `~/.claude/skills`; run by `go-jupyter-sync-skills` (timer), `refresh-user`, and first login | ~5 min after a source's ref moves; clean clones fast-forward, edited clones are left alone |
| template-carried skills `user-templates/*/.claude/skills/**` (now only the tutorial's `exercise`, `recap`) | `go-jupyter-sync-skills` | per skill dir, never over a link; backups kept; if go-skills starts serving one, `link-skills` swaps an unmodified copy for the link (copy kept under `refresh-backups/`), then the template copy can be deleted |
| `news/**` | `go-jupyter-sync-skills` | same; shown at the next session start if changed |
| `CLAUDE.md`, `README.md`, `.bashrc`, `.mcp.json` | `sudo go-jupyter-refresh-user <user>|--all` | only when an operator runs it (`--dry-run` first) |

Neither restarts the hub or touches a running session. A skill change reaches a
running `claude` session on its next invoke; a `CLAUDE.md` change reaches it at
relaunch. After any template change that touches the second row, run the
refresh, or existing homes will carry a `CLAUDE.md` that contradicts their
skills (seen 2026-09-24).

## go-jupyter-update-claude

Keeps the box's global Claude Code install current, semi-automatically
([#39](https://github.com/geneontology/go-jupyter/issues/39)). Installed
to `/usr/local/sbin` by cloud-init and run hourly by
`go-jupyter-update-claude.timer`. It installs the newest npm release that
has been published for at least two days, and only while no curator
session is mid-turn; a live-but-idle session keeps running the old code
and picks the new version up at its next `claude` launch. Because the hub
hands sessions the `opus` / `sonnet` model aliases, a Claude Code update
can also move curators to newer models.

```sh
sudo go-jupyter-update-claude --dry-run     # what would happen now
sudo touch /etc/go-jupyter/hold-claude      # freeze (workshop, bad release)
sudo rm /etc/go-jupyter/hold-claude         # resume
sudo go-jupyter-update-claude --force       # skip the hold and idle gate
journalctl -t go-jupyter-update-claude      # decisions
cat /var/log/go-jupyter-claude-updates.log  # applied updates
```

## go-jupyter-git-identity — commit identity from the GitHub profile

`sudo go-jupyter-git-identity <user>` (or `--all`, `--dry-run`) sets `user.name`
and `user.email` in a user's `~/.gitconfig`, and only when they are unset. The
hub passes `--name` and `--email` from the profile the GitHub sign-in returned;
without them the helper asks the public GitHub API for the login (name, or the
login; public email, or GitHub's `<id>+<login>@users.noreply` address). It runs at first login from the hub's
seed hook for accounts that came in through GitHub OAuth; side-door (PAM)
accounts are skipped and logged. Together with `/etc/gitconfig` (installed from
`etc/gitconfig`: `gh` as git's credential helper for github.com, `push.autoSetupRemote`),
this means a session needs only `gh auth login` before `git push` and `gh pr
create` work (#48). The browser step of that login is #31.
