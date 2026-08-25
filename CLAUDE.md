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
- **Workshop mode is an explicit choice, not a default to leave unexamined.**
  The shipped config runs Claude Code with `--dangerously-skip-permissions` and a
  shared backend key so non-technical curators aren't blocked mid-task. That is
  safe only on a disposable, trusted-participant, time-boxed workshop host. For
  anything else, restore permission prompts and per-user credentials (see the
  README's "Workshop mode" note).
- **Each user is a real Unix account on a shared host.** The hub runs
  privileged to create accounts; treat a hub compromise as a host compromise and
  keep the box disposable.

## Backends

Claude Code talks to either the first-party Claude API (`backend = "anthropic"`,
using an API key file) or Anthropic models on Vertex AI (`backend = "vertex"`,
using a GCP service-account key). The choice is written to
`/etc/default/go-jupyter` and can be flipped in place with a hub restart.
