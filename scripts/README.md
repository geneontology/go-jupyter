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
On the box it is driven by `go-jupyter-refresh-allowlist`:

1. fetch `https://raw.githubusercontent.com/geneontology/go-site/master/metadata/users.yaml`
2. `extract_github_users.py --authorization $GO_JUPYTER_ALLOWLIST_AUTHORIZATION`
   (the variable lives in `/etc/default/go-jupyter`; empty means no filter)
3. replace `/etc/jupyterhub/github_allowed_users.txt` atomically, logging the
   names added and removed; never with an empty list, and not with one that
   lost more than half the names unless `--force`
4. `jupyterhub_config.py` reads that file **at every GitHub sign-in**, so the
   change is live at once; no restart.

It runs from cloud-init before the hub first starts, from
`go-jupyter-refresh-allowlist.timer` every hour, and by hand.
`--dry-run` prints who would be added and removed and which removed names have
a home on the box; `--source <raw URL or file>` previews a `users.yaml` branch
before it merges. Pass `GO_JUPYTER_REPO=<checkout>` to run it from a laptop
against local files (it then uses the extractor next to itself).

## go-jupyter-sync-skills vs go-jupyter-refresh-user — which delivers what

| Template file | Reaches existing homes via | When |
|---|---|---|
| skills from `skill-sources.txt` (go-skills, go-ontology) | `go-jupyter-link-skills <user>` — links `~/.claude/skills/<skill>` into the store, `/var/lib/go-jupyter/skill-sources/<repo>` (one root-owned checkout per source; `--update-store` fetches it; `sparse=` keeps a checkout small; `exclude=` leaves skills out; `workspace` keeps a per-user clone for editing the repository; first source wins a name collision); run by `go-jupyter-sync-skills` (timer: link pass every tick, store fetch when a ref moves), `refresh-user`, and first login | ~5 min after a merge; a curator copy under a canonical name is set aside to `~/.go-jupyter/skill-overrides/`, a curator's own skill under another name is left alone |
| template-carried skills `user-templates/*/.claude/skills/**` (now only the tutorial's `exercise`, `recap`) | `go-jupyter-sync-skills` | per skill dir, never over a link; backups kept; if go-skills starts serving one, `link-skills` swaps an unmodified copy for the link (copy kept under `refresh-backups/`), then the template copy can be deleted |
| `news/**` | `go-jupyter-sync-skills` | same; shown at the next session start if changed |
| `CLAUDE.md`, `README.md`, `.bashrc`, `.mcp.json` | `sudo go-jupyter-refresh-user <user>|--all` | only when an operator runs it (`--dry-run` first: since #98 it prints one `would write` line per file a real run would replace and nothing for a home that already matches; the copy compares content, so a new mtime alone changes nothing) |

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

## go-jupyter-trace-sync — transcript archive, redaction and Langfuse forwarding

Installed to `/usr/local/sbin` by cloud-init and run every five minutes by
`go-jupyter-trace-sync.timer`, as root
([#28](https://github.com/geneontology/go-jupyter/issues/28)). For each
seeded account (the same set `go-jupyter-refresh-user --all` acts on) it
rsyncs `~/.claude/projects/` into `/var/lib/go-jupyter/traces/<user>/projects/`
(root-only, never deleted from; an account whose `~/.claude` or
`~/.claude/projects` is a symlink is skipped), mirrors the archive into
`.../<user>/redacted/` through `go-jupyter-redact-transcript` (credential
values masked, source mtimes kept; `go-jupyter-redact-transcript --self-test`
shows the patterns at work), and, when `/etc/go-jupyter/langfuse.env` is
present and Langfuse answers an authenticated request, runs the vendored
Langfuse hook (`/opt/go-jupyter/vendor/langfuse/langfuse_hook.py`, with
`/opt/go-jupyter/.venv/bin/python`) on every mirrored top-level transcript
whose mtime or size changed since its last successful run, with a `Stop`
payload, or once with `SessionEnd` after a day of quiet. Per-transcript
records live under `/var/lib/go-jupyter/langfuse-state/state/<user>/`; the
hook's own offsets in `langfuse_state.json` next to them. A hook run that
exits non-zero, runs past 120 s or writes to stderr is a failure: logged,
not recorded, stderr kept in `langfuse-state/hook-stderr.log`. The ticks
after a successful run ask Langfuse for the last turn's trace; after three
misses it is logged and written under `langfuse-state/failed/<user>/<session>`
(from one listing of the account's traces per tick rather than one request
per transcript: Langfuse Cloud allows only 5 trace GETs a minute on Hobby, 15
on Core, 40 on Pro, while ingestion has its own far larger bucket; a run
lists at most three accounts, `GO_JUPYTER_LISTS_PER_RUN`, 15 s apart, and a
refused listing pauses the checks for that run, so a backlog drains over the
following ticks).
A transcript over 1 MB that has never been forwarded is imported in slices of
300 lines (`GO_JUPYTER_CHUNK_MIN_BYTES`, `GO_JUPYTER_CHUNK_LINES`), because
each generation's input is the whole earlier conversation and one run over a
long history either exceeds the SDK's request limit or outruns the hook's
final flush.

The curator's `/report` records (`~/.go-jupyter/reports/*.json`, written by
the `report` skill in geneontology/go-skills,
[#25](https://github.com/geneontology/go-jupyter/issues/25)) ride the same
tick: archived to `/var/lib/go-jupyter/traces/<user>/reports/`, then each new
record is posted by `go-jupyter-report-marks` as a Langfuse score
`curator-report` on the trace of the turn it was made in (value = the
category, comment = the curator's note and the agent's context line, both
redacted, plus the issue URL if one was filed; metadata = record file, turn
uuid, skill). The turn is found by walking the archived transcript from the
record's `turn_uuid` to the user row that started the turn and reading that
row's number from the hook's state, so no API request is needed; a record
whose turn the hook has not numbered yet (or whose transcript, or turn, is
not in the archive yet) waits for a later tick, and one that is still
unplaced after a day is scored on the session instead (session scores show
in Langfuse's Sessions tab, not in the trace list). The score is posted with
the synchronous scores API, which fails loudly, and the marker under
`langfuse-state/reports/<user>/` is written only after the API accepted it;
the score id is derived from the record's file name, so a repeat after a
failure updates rather than duplicates. Only the archived copy of the records
is ever read, in a dry run too (which therefore shows the records of the
previous real run, and nothing for an account with no archive yet). A record
that can never be posted (no usable session id, not a regular file, over 1 MB,
unreadable or refused by the API once it is a day old) is marked so it is not
retried forever; `ls langfuse-state/reports/<user>/` shows which. In
Langfuse, filter traces or sessions by the score `curator-report` to find
them; the comment is the curator's note, the agent's context line and the
issue URL if one was filed.

```sh
sudo go-jupyter-trace-sync --dry-run          # what would be archived, forwarded and posted
sudo go-jupyter-trace-sync --user <name>      # one account now
sudo go-jupyter-trace-sync                    # all accounts now (what the timer runs)
journalctl -t go-jupyter-trace-sync           # one summary line per run
ls /var/lib/go-jupyter/traces                 # one directory per account
ls /var/lib/go-jupyter/langfuse-state/failed/*/   # transcripts with a delivery problem
ls /var/lib/go-jupyter/langfuse-state/reports/*/  # /report records already posted
cat /var/lib/go-jupyter/langfuse-state/langfuse_hook.log   # the hook's own log
```

### Deploying on a running box

The helper, the units and the env file are first-boot items that
`go-jupyter-update` does not install (and `go-jupyter-update` restarts the
hub, which this does not need):

```sh
sudo git -C /opt/go-jupyter pull --ff-only
sudo /usr/local/bin/uv sync --project /opt/go-jupyter          # adds langfuse to the hub venv
sudo install -m 0755 /opt/go-jupyter/scripts/go-jupyter-trace-sync /opt/go-jupyter/scripts/go-jupyter-redact-transcript /opt/go-jupyter/scripts/go-jupyter-report-marks /usr/local/sbin/
sudo install -m 0644 /opt/go-jupyter/systemd/go-jupyter-trace-sync.service /opt/go-jupyter/systemd/go-jupyter-trace-sync.timer /etc/systemd/system/
sudo install -d -m 0700 /var/lib/go-jupyter/traces /var/lib/go-jupyter/langfuse-state
sudo install -m 0600 <the operator's langfuse env file> /etc/go-jupyter/langfuse.env
# add "cleanupPeriodDays": 3650 to /etc/claude-code/managed-settings.json
sudo go-jupyter-trace-sync --dry-run
sudo go-jupyter-trace-sync --user <one account>              # then check the Langfuse project
sudo systemctl daemon-reload && sudo systemctl enable --now go-jupyter-trace-sync.timer
```

The first run on a box with history forwards every transcript of every
account; do it account by account with `--user` and watch the Langfuse
project before enabling the timer.

### Re-sending

The hook will not re-read a transcript it has advanced past, and a re-send
into an existing trace adds observations rather than replacing them (trace
ids are deterministic, span ids are not). To re-send one session: delete its
traces in Langfuse (UI, or `DELETE /api/public/traces/<id>` for each turn's
id, `sha256("<session>:<turn>")[:32]`), remove the hook's entry for that
transcript from `langfuse_state.json` (its key is `sha256("<session>::<mirror
path>")`) or the whole file for everything, remove
`langfuse-state/state/<user>/<session>`, and let the next tick run.

To run it elsewhere than the box (a laptop test against directories you
own), set `GO_JUPYTER_ACCOUNTS="<name> ..."`, which bypasses `getent` and the
root check, with `GO_JUPYTER_HOME_ROOT`, `GO_JUPYTER_TRACE_ROOT`,
`GO_JUPYTER_LF_STATE`, `GO_JUPYTER_PYTHON`, `GO_JUPYTER_HOOK`,
`GO_JUPYTER_REDACT`, `GO_JUPYTER_REPORT_MARKS`, `GO_JUPYTER_LANGFUSE_ENV`, `GO_JUPYTER_GITHUB_ALLOWLIST`,
`GO_JUPYTER_LOCK` and `GO_JUPYTER_QUIET_SECS` pointing at your own paths (see
the script header).

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

### Diagnosing the gh hand-off

When a curator's `gh auth status` says they are not logged in after a GitHub
sign-in, check in this order (all as root on the box):

1. Did the sign-in go through GitHub? The hub journal shows
   `GET /hub/github/oauth_callback … -> /hub/spawn (<user>@…)`. Without that
   line the browser reused a hub session and no new token was stored.
2. Is auth state stored, and with which scopes? Decrypt it with the hub's own
   key (the venv, the env file, and `crypto.decrypt`, which returns a Future, so
   await it inside an `async def`):

   ```bash
   set -a; . /etc/jupyterhub/jupyterhub.env; set +a
   /opt/go-jupyter/.venv/bin/python - <<'EOF'
   import asyncio
   from jupyterhub import orm, crypto
   db = orm.new_session_factory("sqlite:////opt/go-jupyter/jupyterhub.sqlite")()
   u = orm.User.find(db, "USER")
   async def main(): return await crypto.decrypt(u.encrypted_auth_state)
   st = asyncio.run(main())
   print(sorted(st), st.get("scope"), (st.get("github_user") or {}).get("login"))
   EOF
   ```

   GitHub returns the granted scopes as one comma-separated string
   (`['read:org,repo,user:email']`); the hook splits it (#77). Print scopes and
   the login, never the token.
3. Run the hook's command by hand and read gh's stderr:
   `runuser -u USER -- env HOME=/home/USER gh auth login --hostname github.com --git-protocol https --with-token < tokenfile`
   (write the token to a root-only temp file from step 2, delete it after).
4. `~/.go-jupyter/no-gh-token` in the home disables the hand-off for that user.

## Testing `go-jupyter-link-skills` without a box

`--home DIR` runs it as the current user against any directory (refused as
root). Point it at a sources file whose entries are local repositories and it
exercises cloning, sparse clones, linking, collisions, exclusions and
dangling-link cleanup end to end. Two things make local repositories work as
sources: initialise them with `main` as the branch, and allow partial clones
when a line uses `sparse=`:

```bash
T=$(mktemp -d)
for r in A B; do
  mkdir -p $T/$r/skills/demo && printf -- '---\nname: demo\n---\n' > $T/$r/skills/demo/SKILL.md
  git -C $T/$r -c init.defaultBranch=main init -q
  git -C $T/$r -c user.name=t -c user.email=t@t add -A
  git -C $T/$r -c user.name=t -c user.email=t@t commit -qm init
  git -C $T/$r config uploadpack.allowFilter true
done
printf 'file://%s main skills\nfile://%s main skills exclude=nothing\n' $T/A $T/B > $T/sources
mkdir -p $T/home/.go-jupyter
scripts/go-jupyter-link-skills --home $T/home --sources $T/sources            # A wins `demo`
scripts/go-jupyter-link-skills --home $T/home --sources $T/sources --no-fetch # second run: no changes
```

Change a repository, commit, run again, and read the log lines; `--dry-run`
prints the commands instead of running them. `--template-skills DIR` stands
in for the template directory when testing the "unmodified template copy is
swapped for the link" rule.
