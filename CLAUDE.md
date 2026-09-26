# go-jupyter — notes for an agent working in this repo

This repo deploys a JupyterHub-on-EC2 box that gives each user an isolated Unix
account with Claude Code + JupyterLab, seeded from a starter template. If you are
an agent helping someone fork and run their own, start with `README.md`, then
this file for the operating rules.

## What lives where

- `terraform/` — the AWS deployment. `variables.tf` is the full input surface;
  `terraform.tfvars.example` is the copy-and-edit starting point. `main.tf`
  provisions the instance/EIP/SG/IAM/DNS; `user_data.sh.tpl` is the cloud-init
  script rendered at apply time.
- `jupyterhub_config.py` — hub auth (PAM and/or GitHub OAuth), the spawner, the
  per-user environment, and first-login home seeding from `user-templates/`.
- `user-templates/<template>/` — a starter home. Files here are copied into a
  user's `/home` once, on first login. Edit these to change what curators get.
  Delivery to *existing* homes is split: `.claude/skills/` and `news/` follow
  `main` automatically (skills-sync timer, ~5 min, and running sessions pick up
  skill text on next invoke); `CLAUDE.md`, `README.md`, `.bashrc`, `.mcp.json`
  reach existing homes only when an operator runs `go-jupyter-refresh-user
  --all`. A template change is not delivered until both have happened (see the
  README's operating notes).
- `scripts/`, `systemd/` — boot and runtime helpers (skills sync timer, user
  add/refresh/migrate).

## Operating rules

- **Secrets are out-of-band, always.** Credentials are referenced by path in the
  gitignored `terraform.tfvars`, read at plan time, and delivered via cloud-init.
  Never write a key, token, or password into a tracked file. If you need a new
  secret, add a variable that takes a *path*, not the value.
- **Tighten the security group before sharing a URL.** `allowed_ssh_cidrs` and
  `allowed_web_cidrs` default to `0.0.0.0/0` for first bring-up.
- **`prevent_destroy` guards the instance** because a replacement wipes every
  user's `/home` (there is no standing backup). Changing `user_data` / `git_ref`
  / a token / the hostname forces replacement — read the plan. Port users with
  `scripts/go-jupyter-migrate` before a deliberate rebuild.
- **First boot writes things `go-jupyter-update` never touches.** The helpers
  in `/usr/local/sbin`, the systemd units, `/etc/claude-code/managed-settings.json`
  and the global Claude Code npm install are all written by cloud-init once.
  `go-jupyter-update` pulls the repo and restarts the hub; it does not reinstall
  any of them. To change one on a running box, change it in the repo *and* put
  the file in place by hand. After any edit to `user_data.sh.tpl`, `terraform
  plan` proposes replacing the instance; that is expected, and not a reason to
  apply it.
- **Apply only what you have read.** `terraform plan -out=<file>` first, then
  `terraform apply <file>` as a separate step; never `-auto-approve`, and never
  chain plan and apply in one command. A plan that destroys anything is a
  decision for the operator, not a detail to scroll past.
- **Workshop mode is an explicit choice, not a default to leave unexamined.**
  The shipped config runs Claude Code with `--dangerously-skip-permissions` and a
  shared backend key so non-technical curators aren't blocked mid-task. That is
  safe only on a disposable, trusted-participant, time-boxed workshop host. For
  anything else, restore permission prompts and per-user credentials (see the
  README's "Workshop mode" note).
- **The drop-box contract is owned by `geneontology/go-cam-drop-box`; the
  skills here implement it.** Since 2026-09-24 a submission is `<dev id>.yaml`
  + `<dev id>.ttl` exported from the stored noctua-dev model; the model's state
  is the curator's, and work in progress is a draft PR. When that contract
  moves, change all of these in the same push, or curators get contradictory
  instructions: `save-to-drop-box/SKILL.md`, the noctua skill's store/export
  section, the template `CLAUDE.md` (skill list and the "where is my work
  safe" table), and `news/NEWS.md`. The drop-box CI rejects a newly added
  legacy-style (single YAML, `gcdb-` id) file with a message pointing at a
  stale session, so a mismatch fails loudly rather than merging.
- **Each user is a real Unix account on a shared host.** The hub runs
  privileged to create accounts; treat a hub compromise as a host compromise and
  keep the box disposable.

## Backends

Claude Code talks to either the first-party Claude API (`backend = "anthropic"`,
using an API key file) or Anthropic models on Vertex AI (`backend = "vertex"`,
using a GCP service-account key). The choice is written to
`/etc/default/go-jupyter` and can be flipped in place with a hub restart.

Model policy (2026-09-22): sessions get `ANTHROPIC_MODEL=fable` and the managed
setting `fallbackModel: ["opus"]`, Claude Code's aliases for the current Fable
and Opus releases, so no model ID is pinned in the repo. Claude Code resolves
the aliases per version, which makes `go-jupyter-update-claude` (hourly timer,
newest npm release at least two days old, idle-gated, frozen by
`/etc/go-jupyter/hold-claude`) the path by which curators reach newer models.
Fable's content-based fallback to Opus is built into Claude Code and needs no
configuration.
