# go-jupyter

A reproducible **JupyterHub-on-EC2** deployment that gives each user an isolated
Unix account with [Claude Code](https://www.anthropic.com/claude-code) and
JupyterLab, seeded from a starter template. The Gene Ontology project uses it to
run **agentic biocuration** workshops — curators work with an AI agent in a
browser terminal — but nothing here is GO-specific by necessity: point it at your
own fork, domain, and templates and you have your own agent workshop box.

This repository is public and self-contained. It contains **no secrets**: every
credential is supplied out-of-band at deploy time (see [Secrets](#secrets)).

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
- **Delivering an instruction change to curators (2026-09-24 procedure).**
  Two delivery paths, and they cover different files:
  - `user-templates/<t>/.claude/skills/` and `news/` are mirrored into every
    seeded home by `go-jupyter-sync-skills.timer` within ~5 minutes of a merge
    to `main`. Per the Claude Code docs, a skill's *body* is read when the
    skill is invoked and the skills directories are watched for changes, so a
    `claude` session that has been running for days still runs the new
    procedure the next time it is asked; only the skill's one-line description
    is fixed at launch. News shows at the start of the next session.
  - The template `CLAUDE.md`, `README.md`, `.bashrc` and `.mcp.json` are *not*
    in the sync set. Existing homes keep their first-login copies until
    `sudo go-jupyter-refresh-user --all` (a file operation with dated backups
    under `~/.go-jupyter/refresh-backups/`; no hub restart; running sessions
    unaffected, though they keep the old `CLAUDE.md` text until relaunched).
    Run it with `--dry-run` first. Forgetting this leaves a home whose
    `CLAUDE.md` contradicts the skill next to it, which is what happened on
    2026-09-24 until the refresh was run.
  Verify by looking at the homes, not the sync log: grep a distinctive phrase
  of the change across `/home/*/.claude/skills/...` and `/home/*/CLAUDE.md`.
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
- **Claude Code's version is not pinned.** Cloud-init installs the current npm
  release at first boot; after that `go-jupyter-update-claude.timer` moves it
  (hourly check, newest release at least two days old, only while no session is
  mid-turn; `touch /etc/go-jupyter/hold-claude` freezes it, see `scripts/`).
  Because sessions run on the `fable` and `opus` model aliases, this is also how
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
