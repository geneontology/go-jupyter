#!/bin/bash
set -euxo pipefail

# cloud-init runs as root. All steps below assume that.

REPO_URL="${git_repo_ssh_url}"
REPO_REF="${git_ref}"
REPO_DIR=/opt/go-jupyter

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
    git curl ca-certificates openssh-client \
    python3 python3-venv python3-pip \
    build-essential

# Swap. The box is memory-bound under concurrent workshop load — several users
# each running Claude Code (Node) + JupyterLab can exhaust the 8 GB of RAM, and
# with no swap the kernel livelocks in memory reclaim and the whole instance
# hard-hangs (no clean OOM-kill — just an unresponsive box needing a reboot). An
# 8 GB swapfile turns that
# into survivable pressure: the OOM-killer can act, or the box thrashes-but-lives
# and stays reachable. swappiness=10 keeps swap out of the way during normal use.
# Idempotent: skip if a swapfile is already active.
if ! swapon --show 2>/dev/null | grep -q '/swapfile'; then
    fallocate -l 8G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=8192 status=none
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
fi
grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
printf 'vm.swappiness=10\n' > /etc/sysctl.d/99-go-jupyter-swap.conf
sysctl -w vm.swappiness=10

# Stock Ubuntu 24.04's /etc/pam.d/login references pam_lastlog.so, but
# that module was removed from libpam-modules and no replacement package
# is in the archive. The `optional` keyword means PAM continues without
# it, but on every PAM auth call (e.g. via PAMAuthenticator) the journal
# logs:
#   PAM unable to dlopen(pam_lastlog.so): ... cannot open shared object file
#   PAM adding faulty module: pam_lastlog.so
# Comment out that line so the warning goes away. /etc/pam.d/login is a
# dpkg conffile; the system's --force-confold policy preserves this edit
# across `apt upgrade`. The sed is idempotent (matches an uncommented line
# only), so re-running cloud-init or the same step on any deployment is safe.
if grep -q '^session.*pam_lastlog.so' /etc/pam.d/login; then
    sed -i 's|^session\(.*\)pam_lastlog.so|# &  # disabled by go-jupyter cloud-init: pam_lastlog.so removed from libpam-modules in Ubuntu 24.04|' /etc/pam.d/login
fi

# Node.js 22.x for Claude Code + configurable-http-proxy.
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g @anthropic-ai/claude-code configurable-http-proxy

# Claude Code managed settings (fleet-wide, not overridable by users):
#   * disable auto-updates (users can't write to /usr/lib/node_modules, and
#     mid-workshop updates are undesirable);
#   * fallbackModel: when the primary model (ANTHROPIC_MODEL, set in
#     jupyterhub_config.py) is overloaded or unavailable, retry the turn on
#     the current Opus release (the 'opus' alias tracks it). Fable's
#     content-based fallback is built into Claude Code.
# NOTE: this file is only written at first boot. To change it on a running
# box, edit /etc/claude-code/managed-settings.json in place as well; editing
# only this template changes user_data, which Terraform treats as an instance
# replacement (blocked by prevent_destroy).
mkdir -p /etc/claude-code
cat > /etc/claude-code/managed-settings.json <<'MANAGED_SETTINGS_EOF'
{"autoUpdatesDisabled": true, "fallbackModel": ["opus"]}
MANAGED_SETTINGS_EOF

# uv, system-wide.
curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# GitHub CLI (gh), from the official apt repo. Used by the researcher template's
# save-to-drop-box skill: users authenticate with `gh auth login` (device flow)
# and the agent opens a PR to geneontology/go-cam-drop-box on their behalf.
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
apt-get update
apt-get install -y gh

# GitHub deploy key (read-only) — only when the source repo is private and a key
# was supplied. A public repo cloned over HTTPS needs none of this.
%{ if deploy_key_private != "" ~}
mkdir -p /root/.ssh
chmod 700 /root/.ssh
cat > /root/.ssh/id_ed25519_go_jupyter <<'DEPLOY_KEY_EOF'
${deploy_key_private}
DEPLOY_KEY_EOF
chmod 600 /root/.ssh/id_ed25519_go_jupyter
ssh-keyscan -t ed25519,rsa github.com >> /root/.ssh/known_hosts 2>/dev/null
chmod 644 /root/.ssh/known_hosts
cat > /root/.ssh/config <<'SSH_CONFIG_EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile /root/.ssh/id_ed25519_go_jupyter
    IdentitiesOnly yes
SSH_CONFIG_EOF
chmod 600 /root/.ssh/config
%{ endif ~}

# Clone the repo.
if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
fi
cd "$REPO_DIR"
git fetch --all --tags
git checkout "$REPO_REF"
git pull --ff-only || true

# Install Python deps into the project venv (jupyterhub_config.py expects .venv/).
uv sync

# GCP service account JSON for Vertex AI. Mode 0644 because the spawned
# single-user processes (running as the workshop user, not root) need to
# read it via GOOGLE_APPLICATION_CREDENTIALS. This is a slight relaxation
# vs the previous CBORG token posture (which lived only in /proc/<pid>/environ
# behind process-isolation); a per-user-copy hardening option is possible later.
%{ if gcp_credentials_json != "" ~}
install -m 0644 /dev/null /etc/gcp-credentials.json
cat > /etc/gcp-credentials.json <<'GCP_CREDS_EOF'
${gcp_credentials_json}
GCP_CREDS_EOF
%{ endif ~}

# Barista token: deliberately NOT written. Barista tokens are personal (ORCID
# login, per-person attribution) and expire, so a shared one baked in at deploy
# both mis-attributes work and is guaranteed to go stale. Each curator supplies
# their own via the noctua skill, stored in their ~/.env.

# Model/provider backend selection, read by jupyterhub_config.py through the
# systemd EnvironmentFile. Written from the Terraform `backend` var, but also
# editable in place for testing (edit + `systemctl restart jupyterhub`) so a
# backend flip doesn't require an instance replacement.
install -m 0644 /dev/null /etc/default/go-jupyter
cat > /etc/default/go-jupyter <<'BACKEND_ENV_EOF'
GO_JUPYTER_BACKEND=${backend}
BACKEND_ENV_EOF

# First-party Claude API key for the 'anthropic' backend (only written when
# the terraform var is non-empty). Mode 0600: the hub reads it as root at
# startup and injects ANTHROPIC_API_KEY into each spawned user's env, so —
# unlike the Vertex creds file — it never needs to be world-readable.
%{ if anthropic_api_key != "" ~}
install -m 0600 /dev/null /etc/anthropic-api-key
cat > /etc/anthropic-api-key <<'ANTHROPIC_KEY_EOF'
${anthropic_api_key}
ANTHROPIC_KEY_EOF
%{ endif ~}

# JupyterHub working dir for sqlite/db files.
mkdir -p /srv/jupyterhub

# JupyterHub config dir for runtime config files (allowlist, env file).
mkdir -p /etc/jupyterhub

# Per-deployment env file consumed by the systemd unit's
# EnvironmentFile= directive. Holds the public hostname and (optionally)
# the GitHub OAuth client id/secret. Mode 0600 because the secret half
# is sensitive; the systemd EnvironmentFile read happens before the unit
# drops privileges (it doesn't, in our case — root throughout — but the
# file mode reflects intent).
install -m 0600 /dev/null /etc/jupyterhub/jupyterhub.env
cat > /etc/jupyterhub/jupyterhub.env <<'JHUB_ENV_EOF'
GO_JUPYTER_HOSTNAME=${hostname}
GITHUB_OAUTH_CLIENT_ID=${github_oauth_client_id}
GITHUB_OAUTH_CLIENT_SECRET=${github_oauth_client_secret}
JHUB_ENV_EOF

# GitHub OAuth allowlist — fetch geneontology/go-site/metadata/users.yaml
# from raw.githubusercontent.com and run extract_github_users.py against
# it. The result is the canonical Tier A allowlist that the production
# branch of jupyterhub_config.py reads at hub startup. This makes every
# fresh deployment automatically pick up the current users.yaml with
# zero operator action; the eventual cron Phase 2 is the same script on
# a systemd timer + `systemctl reload jupyterhub`.
#
# Fail-closed: if the fetch or extraction fails, the file is left empty
# and the OAuth tier rejects everyone. PAM (Tier B) still works.
install -m 0644 /dev/null /etc/jupyterhub/github_allowed_users.txt
if curl -fsSL --retry 3 --retry-delay 2 --max-time 30 \
    https://raw.githubusercontent.com/geneontology/go-site/master/metadata/users.yaml \
    -o /tmp/go-site-users.yaml; then
    if /opt/go-jupyter/scripts/extract_github_users.py /tmp/go-site-users.yaml \
        > /etc/jupyterhub/github_allowed_users.txt.new; then
        mv /etc/jupyterhub/github_allowed_users.txt.new \
           /etc/jupyterhub/github_allowed_users.txt
    else
        echo "extract_github_users.py failed; leaving allowlist empty (OAuth rejects all)" >&2
        rm -f /etc/jupyterhub/github_allowed_users.txt.new
    fi
    rm -f /tmp/go-site-users.yaml
else
    echo "fetch of go-site users.yaml failed; leaving allowlist empty (OAuth rejects all)" >&2
fi
chmod 0644 /etc/jupyterhub/github_allowed_users.txt

install -m 0644 /dev/null /etc/jupyterhub/local_users.txt
cat > /etc/jupyterhub/local_users.txt <<'LOCAL_USERS_HEADER_EOF'
# OOB local users authorized to log in via the username/password chooser
# on the JupyterHub login page (PAMAuthenticator). One username per line.
# Lines starting with # are ignored. Edit via the helpers below — manual
# edits drift the box from Terraform's view, which is OK for the runtime
# add-user case but should be re-synced via `terraform apply` soon after.
LOCAL_USERS_HEADER_EOF

# Pre-create OOB local users from var.local_users at boot, if any.
%{ for u in local_users ~}
useradd --badname -m -s /bin/bash '${u.username}' || true
echo '${u.username}:${u.password}' | chpasswd
echo '${u.username}' >> /etc/jupyterhub/local_users.txt
%{ endfor ~}

# Runtime helper for adding an OOB local user without a Terraform apply.
# Drifts the box from Terraform's view (the new user is in /etc/passwd
# and /etc/jupyterhub/local_users.txt but NOT in var.local_users), which
# is a deliberate carve-out for the workshop / debugging case. Re-sync by
# adding the user to
# terraform.tfvars and re-applying when convenient.
install -m 0755 /dev/null /usr/local/sbin/go-jupyter-add-user
cat > /usr/local/sbin/go-jupyter-add-user <<'ADD_USER_EOF'
#!/usr/bin/env bash
# Usage: sudo go-jupyter-add-user <username>
# Creates a unix user, prompts for a password, adds the name to
# /etc/jupyterhub/local_users.txt, restarts JupyterHub. The home directory is
# seeded on first login by the spawner from the chosen starter template.
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then
    echo "must run as root (try: sudo $0 $*)" >&2
    exit 1
fi
if [ $# -ne 1 ]; then
    echo "usage: $0 <username>" >&2
    exit 1
fi
user="$1"
if ! [[ "$user" =~ ^[a-zA-Z_][a-zA-Z0-9_-]{0,31}$ ]]; then
    echo "invalid username (must be 1-32 chars, [a-zA-Z_][a-zA-Z0-9_-]*)" >&2
    exit 2
fi
if id "$user" >/dev/null 2>&1; then
    echo "user $user already exists; refusing to overwrite" >&2
    exit 3
fi
useradd --badname -m -s /bin/bash "$user"
passwd "$user"   # interactive
# Home is seeded on first login by the spawner's pre_spawn_hook, from the
# starter template the user picks on the spawn page (default: researcher).
echo "$user" >> /etc/jupyterhub/local_users.txt
logger -t go-jupyter-add-user "operator=$${SUDO_USER:-root} action=create user=$user"
systemctl restart jupyterhub
echo "added local user $user; jupyterhub restarted"
ADD_USER_EOF

# Companion remove helper.
install -m 0755 /dev/null /usr/local/sbin/go-jupyter-remove-user
cat > /usr/local/sbin/go-jupyter-remove-user <<'REMOVE_USER_EOF'
#!/usr/bin/env bash
# Usage: sudo go-jupyter-remove-user <username>
# Removes a unix user (with home), drops them from local_users.txt,
# restarts JupyterHub. Refuses to touch users tagged via Terraform —
# those should be removed by editing terraform.tfvars and re-applying.
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then
    echo "must run as root (try: sudo $0 $*)" >&2
    exit 1
fi
if [ $# -ne 1 ]; then
    echo "usage: $0 <username>" >&2
    exit 1
fi
user="$1"
if ! id "$user" >/dev/null 2>&1; then
    echo "user $user does not exist" >&2
    exit 3
fi
# Kill any of the user's processes first — userdel refuses to remove a
# user with active processes (notably, a JupyterHub-spawned single-user
# server). pkill returns 1 if no processes matched, which is fine.
pkill -KILL -u "$user" || true
sleep 1
# userdel -r removes the home dir; -f forces removal even if mail spool
# or login session lingers. We DO want loud failures here, so the
# default `set -e` propagates the exit code rather than silencing it.
userdel -rf "$user"
sed -i "/^$user\$/d" /etc/jupyterhub/local_users.txt
logger -t go-jupyter-remove-user "operator=$${SUDO_USER:-root} action=remove user=$user"
systemctl restart jupyterhub
echo "removed local user $user; jupyterhub restarted"
REMOVE_USER_EOF

# Runtime helper: pull the latest repo state and restart the hub WITHOUT
# replacing the instance, so user home directories persist across config /
# template / backend-code iteration. Drifts the box from Terraform's view in
# the same bounded way as the add/remove-user helpers; re-sync on the next
# `terraform apply`.
install -m 0755 /dev/null /usr/local/sbin/go-jupyter-update
cat > /usr/local/sbin/go-jupyter-update <<'UPDATE_EOF'
#!/usr/bin/env bash
# Usage: sudo go-jupyter-update [git-ref]
# Fetches and checks out /opt/go-jupyter (default: current branch), re-syncs
# Python deps, and restarts JupyterHub. Home directories are NOT touched, so
# users keep their work. NOTE: the restart briefly drops active sessions
# (~5s) — same caveat as the add/remove-user helpers; avoid mid-workshop.
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then
    echo "must run as root (try: sudo $0 $*)" >&2
    exit 1
fi
cd /opt/go-jupyter
git fetch --all --tags
if [ $# -ge 1 ]; then
    git checkout "$1"
fi
git pull --ff-only || true
/usr/local/bin/uv sync
logger -t go-jupyter-update "operator=$${SUDO_USER:-root} action=update ref=$${1:-<current>}"
systemctl restart jupyterhub
echo "go-jupyter updated and restarted"
UPDATE_EOF

# On-demand user-migration helper (ships in the repo). Installed to PATH so it's
# available as `sudo go-jupyter-migrate <old-host>` after a fresh standup.
install -m 0755 "$REPO_DIR/scripts/go-jupyter-migrate" /usr/local/sbin/go-jupyter-migrate

# On-demand template-refresh helper (ships in the repo). Pushes updated skills/
# config into already-seeded users' homes without destroying their work; any
# changed file's previous version is preserved under a dated backup dir.
install -m 0755 "$REPO_DIR/scripts/go-jupyter-refresh-user" /usr/local/sbin/go-jupyter-refresh-user

# systemd unit.
install -m 0644 "$REPO_DIR/systemd/jupyterhub.service" /etc/systemd/system/jupyterhub.service
systemctl daemon-reload
systemctl enable --now jupyterhub.service

# Curator-skill CD: a timer that pulls skill updates from the repo and reconciles
# them into user homes every ~15 min (consumers only; locally-modified skills are
# left alone; backups kept; no hub restart). The box half of the "curators PR
# skills into go-jupyter" flow.
install -m 0755 "$REPO_DIR/scripts/go-jupyter-sync-skills" /usr/local/sbin/go-jupyter-sync-skills
install -m 0644 "$REPO_DIR/systemd/go-jupyter-sync-skills.service" /etc/systemd/system/go-jupyter-sync-skills.service
install -m 0644 "$REPO_DIR/systemd/go-jupyter-sync-skills.timer" /etc/systemd/system/go-jupyter-sync-skills.timer
systemctl daemon-reload
systemctl enable --now go-jupyter-sync-skills.timer

# Caddy: TLS termination + reverse proxy to JupyterHub on localhost:8000.
# The cloudsmith repo is the official Caddy apt source.
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    > /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

# TLS cert: a wildcard cert bundle fetched from S3 via the instance's IAM role
# (NOT per-box Let's Encrypt). This is the GO house pattern and is required
# behind a CDN/WAF, where per-box ACME HTTP-01 challenges get intercepted at the
# edge. The bundle is a certbot tree (tar.gz) whose live/${cert_domain}/ holds
# fullchain.pem + privkey.pem; we resolve those symlinks to flat, caddy-owned
# files so Caddy needs no symlink traversal. Supply it via wildcard_cert_s3_uri.
# AWS CLI v2 (Ubuntu 24.04 has no installable apt 'awscli' package).
apt-get install -y unzip
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws
CERT_TMP="$(mktemp -d)"
/usr/local/bin/aws s3 cp ${wildcard_cert_s3_uri} - | tar xz -C "$CERT_TMP"
mkdir -p /etc/go-wildcard
install -m 0644 -o caddy -g caddy "$(readlink -f "$CERT_TMP/live/${cert_domain}/fullchain.pem")" /etc/go-wildcard/fullchain.pem
install -m 0600 -o caddy -g caddy "$(readlink -f "$CERT_TMP/live/${cert_domain}/privkey.pem")" /etc/go-wildcard/privkey.pem
rm -rf "$CERT_TMP"

cat > /etc/caddy/Caddyfile <<'CADDYFILE_EOF'
${hostname} {
    tls /etc/go-wildcard/fullchain.pem /etc/go-wildcard/privkey.pem
    reverse_proxy 127.0.0.1:8000
}
CADDYFILE_EOF

systemctl reload caddy || systemctl restart caddy
