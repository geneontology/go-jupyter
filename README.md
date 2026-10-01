# go-jupyter

A reproducible **JupyterHub-on-EC2** deployment that gives each user an isolated
Unix account with [Claude Code](https://www.anthropic.com/claude-code) and
JupyterLab, seeded from a starter template. The Gene Ontology project uses it to
run **agentic biocuration** workshops — curators work with an AI agent in a
browser terminal — but nothing here is GO-specific by necessity: point it at your
own fork, domain, and templates and you have your own agent workshop box.

This repository is public and self-contained. It contains **no secrets**: every
credential is supplied out-of-band at deploy time (see [Secrets](#secrets)).

## Background

GO runs this as the **GO AI Hub**, a closed beta for GO curators at
<https://jupyter.geneontology.io> (GitHub login, allowlisted from GO's
`users.yaml`). Each curator gets a Unix account with JupyterLab, a terminal, and
Claude Code preloaded with GO-CAM curation skills: Noctua access through
barista, literature and protein lookups, GO-CAM best practice, and a save path
that submits finished models to
[`go-cam-drop-box`](https://github.com/geneontology/go-cam-drop-box) for review
and promotion into production Noctua.

The approach, the training modules, and the first four-hour workshop with 37
curators are described in Carbon, Moxon, Van Auken, Gaudet and Mungall,
*Agents for Everyone: A Workshop Framework for Building Agentic AI Capabilities
in a Distributed Curation Community* (arXiv:2608.27675,
<https://arxiv.org/abs/2608.27675>, August 2026). Its conclusion is the design
brief for this repo: remove technical barriers, introduce capabilities
gradually, and ground exercises in familiar curation tasks.

The [AI4Curators guides](https://ai4curation.io/aidocs/) are the companion to
this repo: what agents, skills and harnesses are, and patterns from other
curation projects. Their
[GO AI Hub page](https://ai4curation.io/aidocs/case-studies/go-ai-hub/)
describes the hub for curators, with figures from the paper.

## Writing and sharing skills

Skills are not written in this repo. Two guides already cover them, so this
section only adds what is particular to the hub:

- **How to write a good skill:** the
  [AI4Curators skills guide](https://ai4curation.io/aidocs/how-tos/author-skills/).
- **How to change or propose one from a hub session** (branch, try it, push,
  pull request, back to `main`): go-skills'
  [CONTRIBUTING.md](https://github.com/geneontology/go-skills/blob/main/CONTRIBUTING.md).

What the hub adds:

- Curators' skills come from every source in [`skill-sources.txt`](skill-sources.txt):
  `~/go-skills` and `~/go-ontology` (ontology editing skills; changes go to
  go-ontology, not go-skills). `ls -l ~/.claude/skills` shows which is which.
- **A new skill is not linked until the source moves on `main`.** A draft in
  `~/go-skills/skills/<name>/` on a branch is invisible to Claude until you link
  it yourself: `ln -s ../../go-skills/skills/<name> ~/.claude/skills/<name>`.
  If you switch back to `main` before it merges, the next sync removes the
  dangling link.
- **A plain directory in `~/.claude/skills/` is a personal skill.** The sync never
  touches it, and nobody else gets it.
- Where a new skill belongs: GO curation any curator does → go-skills; ontology
  editing → go-ontology `.claude/skills/`; one group or model organism database →
  that group's repository or a personal skill. The tutorial's `exercise` and
  `recap` stay in `user-templates/tutorial/` by decision.

## Architecture

```
        Cloudflare / DNS (optional)
                 │
          :443   ▼
        ┌─────────────────── EC2 (Ubuntu 24.04) ───────────────────┐
        │  Caddy  ──TLS──►  JupyterHub (127.0.0.1:8000)             │
        │                     │ spawns a single-user server        │
        │                     ▼   per Unix account                 │
        │  /home/<user>/  ← seeded once from user-templates/<t>/    │
        │     └─ Claude Code (anthropic | vertex backend)          │
        └───────────────────────────────────────────────────────────┘
```

- **Terraform** (`terraform/`) provisions the instance in an existing VPC/subnet,
  an Elastic IP, a security group, an instance IAM role, and (in `direct`
  fronting) a Route53 A record.
- **cloud-init** (`terraform/user_data.sh.tpl`) installs the stack, clones this
  repo, and writes the hub config. Re-running it replaces the instance, so a
  `prevent_destroy` guard protects the users' home directories.
- **JupyterHub** (`jupyterhub_config.py`) authenticates users (PAM and/or GitHub
  OAuth), spawns a per-user server, and seeds each new home from a chosen
  template.
- **Caddy** terminates TLS using a wildcard cert bundle you supply from S3
  (`wildcard_cert_s3_uri`), fetched at boot via the instance IAM role so the
  private key never touches Terraform state. (Per-host Let's Encrypt is not
  wired in this version.)
- **Starter templates** (`user-templates/`) are plain files (skills, docs,
  dotfiles) copied into a user's home on first login. A systemd timer keeps the
  skills in sync with the repo.

## Deploy your own

Prerequisites: an AWS account with a VPC/subnet, an SSH keypair, a Route53 zone
you control, a wildcard TLS cert bundle (certbot tree, tar.gz) in an S3 bucket
you control, and an agent backend key (a Claude API key, or a GCP service
account for Vertex). `route53_zone_name` and `wildcard_cert_s3_uri` are required.
The VPC and subnet are found by their `Name` tags (`vpc_name_tag`,
`subnet_name_tag`, both default `default`); set them if yours differ.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # then edit — see the comments in it
terraform init
terraform apply
```

Point `git_repo_ssh_url` at your own fork to serve your own skills and
templates. `terraform.tfvars`, state, and any `*-inventory` files are
gitignored.

## Curator access and workshop mode

Users log in over HTTPS (PAM accounts you seed, or GitHub OAuth) and land in a
JupyterLab with a terminal. Each gets a real Unix account on a shared host.

> **Workshop-mode tradeoff, stated plainly.** As shipped, the launcher and the
> seeded shell start Claude Code with `--dangerously-skip-permissions` (and the
> launcher additionally with `--trust-workspace`) so non-technical curators
> aren't stopped by per-action confirmation prompts, and the agent backend key
> is shared across users. This is appropriate only for a
> **controlled, time-boxed workshop on a disposable host with trusted
> participants**. For anything longer-lived, turn permission prompts back on
> (remove that flag in `user-templates/*/.bashrc` and
> `jupyter-data/jupyter_app_launcher/jp_app_launcher.yaml`) and give each user
> their own backend credential. Hardening this into a safe default is on the
> roadmap.

## Secrets

Nothing sensitive lives in this repo. Credentials are referenced by path in your
gitignored `terraform.tfvars`, read at plan time, and delivered to the box via
cloud-init (never committed, never in the repo's history):

- agent backend key → `/etc/anthropic-api-key` or `/etc/gcp-credentials.json`
- GitHub deploy key (only if your source repo is private) → baked into user_data
- optional NCBI E-utilities key → `NCBI_API_KEY` in `/etc/default/go-jupyter`
- JupyterHub auth-state key (`JUPYTERHUB_CRYPT_KEY`) → generated on the box at
  first boot into `/etc/jupyterhub/jupyterhub.env`; not an operator secret. It
  encrypts the GitHub OAuth token the hub keeps between sign-in and spawn so
  that `gh` can be logged in with it (see the operating notes).

## Operating notes

- **A hub restart ends every running single-user server**, including open
  terminals and any `claude` session inside them (files on disk are safe). The
  runtime helpers `go-jupyter-add-user` and `go-jupyter-remove-user` both end in
  a restart, so run them between sessions, not during one.
- **Idle is not the same as absent.** Curators leave JupyterLab tabs and
  `claude` processes running for days. To know whether anyone is *working*,
  read the timestamp of the last `user`/`assistant` entry in each
  `~<user>/.claude/projects/*/*.jsonl` (the files are append-only). Two signals
  that look right but are not: those files' mtimes, which idle `claude`
  processes bump every few minutes, and the hub's `last_activity`, which an
  open browser tab keeps fresh by polling.
- **Replacing the box (blue/green).** Bring up a second stack from a separate
  Terraform state with the same `fronting` and hostname, verify it, then on the
  new box run `go-jupyter-migrate <old-host>` (see the script header for the
  agent-forwarding form that never copies a key). The sequence that worked for
  the 2026-09-22 cutover, in order:
  1. Full `go-jupyter-migrate` while the old hub is still up. Re-running it
     later is safe: it skips accounts that already exist and adds any created
     on the old box since.
  2. In a quiet window, `systemctl stop jupyterhub` on the old box. With the
     default spawner every single-user server and `claude` process is a child
     of the hub, so this ends them all and nothing can change there afterwards.
  3. `go-jupyter-migrate <old-host>` again for the final delta, then
     `go-jupyter-refresh-user --all` on the new box: the rsync brings the old
     box's copies of the template-owned files (skills, `CLAUDE.md`, `.bashrc`)
     over what first-login seeding put there, and the skills-sync timer will
     not correct that because it only acts when `main` moves.
  4. Restart the new hub. Repoint the hostname at the new EIP: the Route53
     record via Terraform for `fronting = "direct"`, the CDN-side origin record
     by hand for `fronting = "cloudflare"`. Verify with a tagged request through
     the edge (`/hub/login?probe=…`) and grep the new hub's journal for it.
  5. Destroy the old stack from a saved plan (`terraform plan -destroy -out=…`,
     then `terraform apply <file>`) so the destroy count is visible before
     anything changes.
  Do not run a blanket rsync from the old box after the repoint: `rsync -a`
  copies whatever differs, so old copies would overwrite files written on the
  new box since. Copy per user, on request, if someone kept working on the old
  box through a still-open WebSocket.
- **Where skills come from, and how changes reach curators (since 2026-09-28).**
  Skills live in their own repositories, listed one per line in
  `skill-sources.txt` (geneontology/go-skills first, geneontology/go-ontology
  second). Every seeded account holds a real git clone of each source in its
  home (`~/go-skills`, `~/go-ontology`), owned by the user, and
  `~/.claude/skills/<skill>` is a relative symlink into that clone. A source
  can be cloned blobless and sparse (`sparse=` option: go-ontology comes as its
  skills plus `src/ontology`, about 210 MB instead of gigabytes) and can leave
  skills out (`exclude=`: the two that need the ODK Docker image). Two sources
  offering the same skill name: the first listed wins, the other is logged.
  Everything for everyone: no per-template list. The timer
  (`go-jupyter-sync-skills`) checks each source's ref with one `ls-remote` per
  tick and, when it moved, runs `go-jupyter-link-skills` for every user: a
  clone that is clean on its ref is fast-forwarded; one on a branch or with
  local changes is left alone and logged, because that is a curator editing a
  skill. Claude Code follows the links and watches the targets, so an edit in
  the clone is live in the session; a running session picks up new upstream
  text on its next invoke of the skill. News still mirrors from the template
  (`news/`) and shows at the next session start. The template `CLAUDE.md`,
  `README.md`, `.bashrc` and `.mcp.json` still reach existing homes only via
  `sudo go-jupyter-refresh-user --all` (dry-run first). Verify by looking at
  the homes: `ls -l /home/*/.claude/skills` shows links into `~/go-skills`.
  When a change touches both `go-jupyter-link-skills` and `skill-sources.txt`,
  install the helper on the box before merging: the timer runs the installed
  helper against the merged file within minutes.
  Skills that a template still carries as real directories (only the tutorial's
  workshop-specific `exercise` and `recap`, kept out of go-skills by decision)
  are mirrored per skill directory, never with a whole-directory delete. When
  go-skills starts serving a skill a template also carries, `link-skills`
  replaces a home's copy with the link once the copy is byte-identical to the
  template's (the copy is kept under `~/.go-jupyter/refresh-backups/`); a copy
  the curator changed stays, and is logged. Delete the template copy from the
  repo only after that has happened in every home. The seven GO-CAM skills went
  through exactly this on 2026-09-28.
- **The drop-box save is a two-file export from noctua-dev (since 2026-09-24).**
  The contract itself lives in
  [`geneontology/go-cam-drop-box`](https://github.com/geneontology/go-cam-drop-box)
  (README, `CLAUDE.md`, `PROMOTIONS.md`); the `save-to-drop-box` skill here must
  match it. What an operator of this box needs to know: curators build models on
  noctua-dev through barista; the gocam-py YAML is derived on the box from the
  minerva JSON returned by the m3 `get` operation, and the Turtle that actually
  enters production comes from the m3 `export` operation, both taken from the
  same **stored** state of the dev model under its dev-minted id. Storing is not
  automatic: of the first 22 submissions, 9 had never been stored and were gone
  from noctua-dev after its next restart, so no Turtle existed for them. Merged
  pairs are copied into `noctua-models` at a Noctua maintenance outage with the
  id unchanged (first batch: 12 models, 2026-09-24).
- **Signing in with GitHub also signs in `gh` (since 2026-09-29).** The hub
  requests `repo`, `read:org` and `user:email`, stores the token as encrypted
  auth state, and at every spawn runs `gh auth login --with-token` as the user
  when gh is not already logged in (and `~/.go-jupyter/no-gh-token` is absent).
  `/etc/gitconfig` makes gh git's credential helper, and the first-login seed
  sets the commit identity from the GitHub profile, so `git push` and `gh pr
  create` work with no further steps. Manual `gh auth login` remains the
  fallback (PAM accounts, revoked tokens). Rolling the scopes forward makes
  GitHub re-ask every user for consent at their next sign-in; announce it in
  `news/`.
- **Claude Code's version is not pinned.** Cloud-init installs the current npm
  release at first boot; after that `go-jupyter-update-claude.timer` moves it
  (hourly check, newest release at least two days old, only while no session is
  mid-turn; `touch /etc/go-jupyter/hold-claude` freezes it, see `scripts/`).
  Because sessions run on the `opus` and `sonnet` model aliases, this is also how
  curators reach newer models.
- **Port 8000 is not loopback-only.** `jupyterhub_config.py` sets no
  `bind_url`, so the proxy listens on all interfaces; only the security group
  (80/443/22) keeps it off the internet. Caddy reaches it at `127.0.0.1:8000`,
  so binding it to loopback is a safe hardening if you tighten further.

## Repo layout

| Path | What |
|---|---|
| `terraform/` | AWS provisioning (instance, EIP, SG, IAM, DNS) |
| `jupyterhub_config.py` | Hub auth, spawner, per-user env and home seeding |
| `user-templates/` | Starter homes (skills, docs, dotfiles) seeded per user |
| `scripts/` | Boot/runtime helpers (skills sync, Claude Code updater, user add/refresh/migrate) |
| `systemd/` | Units for the hub, the skills-sync timer and the Claude Code update timer |
| `justfile` | Common operator commands |

## License

See `LICENSE`.
