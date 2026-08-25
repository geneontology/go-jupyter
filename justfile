tf_dir := "terraform"
export CHECKPOINT_DISABLE := "1"

# --- Terraform (AWS deployment) ---

# Plan infrastructure changes
tf-plan:
    terraform -chdir={{tf_dir}} plan

# Apply infrastructure changes
tf-apply:
    terraform -chdir={{tf_dir}} apply

# Tear down all infrastructure
tf-destroy:
    terraform -chdir={{tf_dir}} destroy

# SSH into the EC2 instance
tf-ssh:
    #!/usr/bin/env bash
    IP=$(terraform -chdir={{tf_dir}} output -raw public_ip)
    ssh -i ~/.ssh/go-jupyter \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ubuntu@"$IP"

# Show deployment info
tf-status:
    terraform -chdir={{tf_dir}} output

# View JupyterHub logs on the instance
tf-logs:
    #!/usr/bin/env bash
    IP=$(terraform -chdir={{tf_dir}} output -raw public_ip)
    ssh -i ~/.ssh/go-jupyter \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ubuntu@"$IP" 'sudo journalctl -u jupyterhub --no-pager -n 50'

# Reset a single user (delete + they re-register with fresh template)
tf-reset-user user:
    #!/usr/bin/env bash
    IP=$(terraform -chdir={{tf_dir}} output -raw public_ip)
    ssh -i ~/.ssh/go-jupyter \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ubuntu@"$IP" "sudo go-jupyter-remove-user {{user}}"

# Reset all users (nuclear option — everyone re-registers)
tf-reset-all-users:
    #!/usr/bin/env bash
    IP=$(terraform -chdir={{tf_dir}} output -raw public_ip)
    ssh -i ~/.ssh/go-jupyter \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ubuntu@"$IP" 'for user in $(grep ":/home/" /etc/passwd | cut -d: -f1); do sudo go-jupyter-remove-user "$user"; done'

# Push latest git changes to running instance and restart hub
tf-deploy:
    #!/usr/bin/env bash
    IP=$(terraform -chdir={{tf_dir}} output -raw public_ip)
    ssh -i ~/.ssh/go-jupyter \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        ubuntu@"$IP" 'sudo git -C /opt/go-jupyter pull && sudo systemctl restart jupyterhub'

# --- Local development ---

# Start JupyterHub locally
serve port="9000":
    .venv/bin/jupyterhub -f jupyterhub_config.py --port {{port}}

# --- Skills management (prepares user-templates/*) ---

# Skill sources
skill_sources := "~/repos/gocam-agent:.claude/skills external-skills/claude-scientific-skills:scientific-skills"

# Cherry-picked skills from external repos
selected_external_skills := "uniprot-database"

# Clone/update external skill repos
fetch-skills:
    mkdir -p external-skills
    cd external-skills && \
        ([ -d claude-scientific-skills ] && git -C claude-scientific-skills pull || \
         git clone https://github.com/aledlie/claude-scientific-skills.git)

# Sync skills into every user template (researcher + tutorial). Each named
# skill is synced individually, so template-specific skills (e.g. tutorial's
# exercise/recap) are left untouched.
sync-skills:
    for tmpl in user-templates/researcher user-templates/tutorial; do \
        mkdir -p "$tmpl/.claude/skills"; \
        for skill in ~/repos/gocam-agent/.claude/skills/*; do \
            [ -e "$skill" ] || continue; \
            echo "Syncing $(basename "$skill") from gocam-agent -> $tmpl"; \
            rsync -a --delete "$skill" "$tmpl/.claude/skills/"; \
        done; \
        for name in {{selected_external_skills}}; do \
            skill="external-skills/claude-scientific-skills/scientific-skills/$name"; \
            [ -e "$skill" ] || { echo "WARNING: $name not found"; continue; }; \
            echo "Syncing $name from claude-scientific-skills -> $tmpl"; \
            rsync -a --delete "$skill" "$tmpl/.claude/skills/"; \
        done; \
    done
