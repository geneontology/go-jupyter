import os
import re
import shutil
import subprocess

config_dir = os.path.dirname(os.path.abspath(__file__))
venv_bin = os.path.join(config_dir, '.venv', 'bin')
env = {'PATH': f'{venv_bin}:/usr/local/bin:{os.environ.get("PATH", "")}'}

# ---------------------------------------------------------------------------
# Model / provider backend abstraction.
#
# Claude Code can reach Anthropic models through several backends. We keep the
# choice behind a single named-profile switch so an operator can move between
# them (or a future one) by flipping GO_JUPYTER_BACKEND, without editing model
# literals scattered through this file. The active backend is delivered by
# cloud-init to /etc/default/go-jupyter (from the Terraform `backend`
# variable) and read into the hub process env via the systemd EnvironmentFile.
# It can also be flipped in place on the box for testing (edit that file and
# `systemctl restart jupyterhub`).
#
# Each profile sets the provider env vars AND the model IDs, because the two
# are coupled: the first-party Anthropic API uses bare model IDs throughout,
# while Vertex uses bare IDs for current-generation (4.6+) models but the
# `@`-versioned form for dated snapshots like Haiku 4.5.
#
# Models (2026-07): the main model is Opus 4.8; users switch to Sonnet 5
# in-session via Claude Code's `/model`. Haiku 4.5 fills the two internal,
# non-user-facing slots (small/fast background calls + subagents) purely for
# cost. Each profile no-ops if its credential file is absent (e.g. local dev),
# leaving Claude Code to fall back to whatever is in the developer's own env.
# ---------------------------------------------------------------------------
GCP_CREDENTIALS_FILE = '/etc/gcp-credentials.json'
ANTHROPIC_API_KEY_FILE = '/etc/anthropic-api-key'


def _anthropic_backend(env):
    """First-party Claude API (api.anthropic.com). The credits-account key is
    delivered by cloud-init to ANTHROPIC_API_KEY_FILE."""
    if not os.path.exists(ANTHROPIC_API_KEY_FILE):
        return
    with open(ANTHROPIC_API_KEY_FILE) as f:
        env['ANTHROPIC_API_KEY'] = f.read().strip()
    env['ANTHROPIC_MODEL'] = 'claude-opus-4-8'
    env['ANTHROPIC_SMALL_FAST_MODEL'] = 'claude-haiku-4-5'
    env['CLAUDE_CODE_SUBAGENT_MODEL'] = 'claude-haiku-4-5'


def _vertex_backend(env):
    """Anthropic models on Vertex AI in GCP. The consumer service-account JSON
    is delivered by cloud-init to GCP_CREDENTIALS_FILE. Provisioning lives in
    geneontology/budget-enforcer; this repo is the consumer side."""
    if not os.path.exists(GCP_CREDENTIALS_FILE):
        return
    env['CLAUDE_CODE_USE_VERTEX'] = '1'
    env['CLOUD_ML_REGION'] = 'us-east5'
    env['ANTHROPIC_VERTEX_PROJECT_ID'] = 'gene-ontology-465618'
    env['GOOGLE_APPLICATION_CREDENTIALS'] = GCP_CREDENTIALS_FILE
    env['ANTHROPIC_MODEL'] = 'claude-opus-4-8'
    env['ANTHROPIC_SMALL_FAST_MODEL'] = 'claude-haiku-4-5@20251001'
    env['CLAUDE_CODE_SUBAGENT_MODEL'] = 'claude-haiku-4-5@20251001'


BACKENDS = {
    'anthropic': _anthropic_backend,
    'vertex': _vertex_backend,
}
DEFAULT_BACKEND = 'anthropic'

backend_name = (
    os.environ.get('GO_JUPYTER_BACKEND', DEFAULT_BACKEND).strip() or DEFAULT_BACKEND
)
if backend_name not in BACKENDS:
    raise ValueError(
        f"unknown GO_JUPYTER_BACKEND {backend_name!r}; "
        f"expected one of {sorted(BACKENDS)}"
    )
BACKENDS[backend_name](env)

# Common Claude Code env (backend-independent).
env['DISABLE_NON_ESSENTIAL_MODEL_CALLS'] = '1'
env['DISABLE_TELEMETRY'] = '1'
env['DISABLE_AUTOUPDATER'] = '1'
env['CLAUDE_CODE_MAX_OUTPUT_TOKENS'] = '8192'

# Reduce scrollbar reset issues in xterm.js/JupyterLab terminals.
# See: anthropics/claude-code#36128, #34845, #34400
env['CLAUDE_CODE_NO_FLICKER'] = '1'

# NCBI E-utilities API key (optional; raises the rate limit from 3 to 10
# req/sec). Supplied out-of-band, never committed: set NCBI_API_KEY in
# /etc/default/go-jupyter, or place the key in /etc/ncbi-api-key (mode 0600).
# Absent = unauthenticated E-utilities, which still work.
_ncbi_key = os.environ.get('NCBI_API_KEY', '').strip()
if not _ncbi_key and os.path.exists('/etc/ncbi-api-key'):
    with open('/etc/ncbi-api-key') as _n:
        _ncbi_key = _n.read().strip()
if _ncbi_key:
    env['NCBI_API_KEY'] = _ncbi_key

# NOTE: BARISTA_TOKEN is deliberately NOT injected.
#
# A barista token is personal, not a service credential: it comes from a human
# ORCID login, carries that person's identity (models are attributed to it), and
# expires. A single shared token baked in at deploy time is therefore wrong twice
# over — it mis-attributes everyone's work to one ORCID, and it eventually
# expires, at which point every user is left with a dead token and hits "You are
# using a bad token" the first time they try to create a model, after doing the
# work.
#
# Injecting nothing is strictly better than injecting something broken: the
# noctua skill checks for a token up front, walks the curator through the ORCID
# login, and persists it to their own ~/.env. See the noctua skill's "Tokens"
# section.

c.Spawner.environment = env

# ---------------------------------------------------------------------------
# Per-user starter templates.
#
# Each new user picks a starter environment at spawn time (JupyterHub options
# form); the choice seeds their $HOME from user-templates/<name>/ on first
# login. 'researcher' (the open-ended biocuration playground) is the default;
# 'tutorial' is the graded workshop curriculum. The choice is first-login
# only — once a home is seeded (.seeded marker) the form is suppressed and the
# existing environment is reused, so template edits never clobber a returning
# user's work.
# ---------------------------------------------------------------------------
TEMPLATE_ROOT = os.path.join(config_dir, 'user-templates')
TEMPLATES = ('researcher', 'tutorial')
DEFAULT_TEMPLATE = 'researcher'
TEMPLATE_LABELS = {
    'researcher': 'Researcher — open-ended biocuration playground (recommended)',
    'tutorial': 'Tutorial — guided workshop exercises',
}

# Participant-facing usage/monitoring notice, shown on the first-login spawn
# page (the account-creation moment) and echoed in each template's welcome
# banner and README. Wording is deliberately broad — it holds
# whether or not per-user telemetry is enabled.
USAGE_NOTICE_TEXT = (
    "This is a shared, monitored environment. Your activity and usage — "
    "including system and session logs and usage traces — may be reviewed to "
    "analyze and improve the service. Please don't store personal secrets here."
)

IS_ROOT = os.getuid() == 0


def _read_username_list(path):
    """Read a one-username-per-line file, ignoring blanks and `#` comments."""
    if not os.path.exists(path):
        return set()
    with open(path) as f:
        return {
            line.strip()
            for line in f
            if line.strip() and not line.startswith('#')
        }


def _home_dir(username):
    """Where a user's home lives — real home under root, a local-users/
    subdir under the local-dev spawner."""
    if IS_ROOT:
        return os.path.expanduser(f'~{username}')
    return os.path.join(config_dir, 'local-users', username)


def _template_dir(name):
    """Resolve a template name to its directory, falling back to the default
    if the name is unknown or its directory is missing — so a bad or stale
    selection can never break a spawn."""
    if name not in TEMPLATES:
        name = DEFAULT_TEMPLATE
    path = os.path.join(TEMPLATE_ROOT, name)
    if not os.path.isdir(path):
        path = os.path.join(TEMPLATE_ROOT, DEFAULT_TEMPLATE)
    return path


def _selected_template(spawner):
    """The validated template the user chose on the spawn form; DEFAULT_TEMPLATE
    when absent (direct/API spawn, or an already-seeded home)."""
    choice = (spawner.user_options or {}).get('template', DEFAULT_TEMPLATE)
    return choice if choice in TEMPLATES else DEFAULT_TEMPLATE


def template_options_form(spawner):
    """Render the starter-template chooser on the spawn page — but only on
    first login. Once the user's home is seeded, return '' so JupyterHub skips
    the form and spawns straight into their existing environment."""
    if os.path.exists(os.path.join(_home_dir(spawner.user.name), '.seeded')):
        return ''
    options = []
    for name in TEMPLATES:
        selected = ' selected' if name == DEFAULT_TEMPLATE else ''
        label = TEMPLATE_LABELS.get(name, name)
        options.append(f'<option value="{name}"{selected}>{label}</option>')
    notice = (
        '<div class="alert alert-warning" role="alert" style="margin-bottom:1em;">'
        f'<strong>Notice.</strong> {USAGE_NOTICE_TEXT}'
        '</div>'
    )
    return (
        notice
        + '<label for="template">Choose your starter environment:</label>'
        '<select class="form-control" name="template" id="template">'
        + ''.join(options)
        + '</select>'
    )


def template_options_from_form(formdata):
    """Parse the chooser selection into spawner.user_options."""
    choice = formdata.get('template', [DEFAULT_TEMPLATE])
    if isinstance(choice, list):
        choice = choice[0] if choice else DEFAULT_TEMPLATE
    return {'template': choice if choice in TEMPLATES else DEFAULT_TEMPLATE}


if IS_ROOT:
    # Production deployment auth/authz model. for
    # the design rationale: one bimodal hub via jupyterhub-multiauthenticator,
    # Tier A (GitHub OAuth) for the 99%, Tier B (PAM side door) for OOB local
    # users.
    #
    # Tier B (PAM): authenticates real unix users on the box against
    # /etc/shadow. OOB local users are created either at boot by cloud-init
    # from var.local_users, or imperatively via the
    # `sudo go-jupyter-add-user <name>` helper installed by user_data. The
    # allowed PAM usernames are read from /etc/jupyterhub/local_users.txt
    # (written by both delivery paths). Tier B is always present.
    #
    # Tier A (GitHub OAuth): added to the multiauthenticator list ONLY when
    # GITHUB_OAUTH_CLIENT_ID and GITHUB_OAUTH_CLIENT_SECRET are present in
    # the hub process's env. cloud-init writes them (and GO_JUPYTER_HOSTNAME)
    # to /etc/jupyterhub/jupyterhub.env, which the systemd unit pulls in via
    # EnvironmentFile=. A deployment without OAuth credentials simply runs
    # with PAM as the only sub-authenticator and the login chooser collapses
    # to a single option.
    from jupyterhub.auth import PAMAuthenticator
    from multiauthenticator.multiauthenticator import MultiAuthenticator

    # Local subclass of multiauthenticator with two upstream-design fixes:
    #
    # 1. **Per-URL-scope chooser button labels.** Multiauthenticator's
    #    `__init__` has an if/elif chain where setting `username_prefix`
    #    (which we MUST set to "" — see below) silently suppresses the
    #    `service_name` config-dict path. The chooser then falls back to
    #    `authenticator.login_service`, which we can't set on a form-based
    #    authenticator like PAM without tripping JupyterHub's
    #    `elif login_service` branch in login.html and creating a render
    #    loop at /hub/local/login. We bypass multiauthenticator's label
    #    resolution entirely and look up labels per URL scope.
    #
    # 2. **Visible spacing between chooser buttons.** The default chooser
    #    stacks `<div class="service-login">` blocks with no margin, so
    #    they collide visually. We add an inline `margin-bottom`.
    #
    # If a third sub-authenticator is added later, add its URL scope to
    # CHOOSER_BUTTON_LABELS below or it will fall back to a generic label.
    class GoJupyterMultiAuthenticator(MultiAuthenticator):
        CHOOSER_BUTTON_LABELS = {
            '/local': 'username and password',
            '/github': 'GitHub',
        }

        def get_custom_html(self, base_url):
            html_parts = []
            for authenticator in self._authenticators:
                scope = getattr(authenticator, 'url_scope', '')
                label = self.CHOOSER_BUTTON_LABELS.get(
                    scope,
                    authenticator.login_service or scope.lstrip('/') or 'login',
                )
                url = authenticator.login_url(base_url)
                html_parts.append(
                    f"""
                    <div class="service-login" style="margin-bottom: 1em;">
                      <a role="button" class='btn btn-jupyter btn-lg' href='{url}{{% if next is defined and next|length %}}?next={{{{next}}}}{{% endif %}}'>
                        Sign in with {label}
                      </a>
                    </div>
                    """
                )
            return "\n".join(html_parts)

    local_users_file = '/etc/jupyterhub/local_users.txt'
    pam_allowed_users = _read_username_list(local_users_file)

    c.JupyterHub.authenticator_class = GoJupyterMultiAuthenticator

    # Disable multiauthenticator's username prefixing entirely. The default
    # behavior is to prepend `${login_service}:` to every username so PAM
    # `kltm` becomes `local:kltm` and GitHub `kltm` becomes `github:kltm`.
    # That breaks the LocalProcessSpawner / pre_spawn_hook chain because
    # `:` is not a valid POSIX username character. Empty prefix means the
    # two populations share a unix-user namespace — which is what we want
    # for people who log in via both paths (same human, same /home).
    # The username collision rule in go-jupyter-add-user (which refuses to
    # create an OOB local user that already exists) handles new conflicts.
    c.MultiAuthenticator.username_prefix = ""

    c.MultiAuthenticator.authenticators = [
        (
            PAMAuthenticator,
            '/local',
            {
                'allowed_users': pam_allowed_users,
                # PAMAuthenticator opens its own PAM session, which on Ubuntu
                # creates the home directory if mkhomedir is enabled. Our
                # cloud-init creates homes explicitly so this is belt-and-braces.
                'open_sessions': True,
            },
        ),
    ]

    github_oauth_client_id = os.environ.get('GITHUB_OAUTH_CLIENT_ID', '').strip()
    github_oauth_client_secret = os.environ.get('GITHUB_OAUTH_CLIENT_SECRET', '').strip()
    public_hostname = os.environ.get('GO_JUPYTER_HOSTNAME', '').strip()
    if github_oauth_client_id and github_oauth_client_secret and public_hostname:
        from oauthenticator.github import GitHubOAuthenticator

        # Lowercase incoming GitHub logins so the spawned unix users are
        # consistent (a handful of go-site users have capitals like
        # 'CY-uniprot' and we want them spawned as 'cy-uniprot'). Subclass
        # rather than fighting traitlets to accept a callable.
        class LowercasedGitHubOAuthenticator(GitHubOAuthenticator):
            def normalize_username(self, username):
                return super().normalize_username(username.lower())

        # Source of truth: cloud-init fetches users.yaml from go-site at
        # boot, runs extract_github_users.py, and writes the result here.
        #
        github_allowed_users = _read_username_list(
            '/etc/jupyterhub/github_allowed_users.txt'
        )
        c.MultiAuthenticator.authenticators.append((
            LowercasedGitHubOAuthenticator,
            '/github',
            {
                'client_id': github_oauth_client_id,
                'client_secret': github_oauth_client_secret,
                'oauth_callback_url': (
                    f'https://{public_hostname}/hub/github/oauth_callback'
                ),
                'allowed_users': github_allowed_users,
            },
        ))


    # Production: real unix users with process isolation
    import json
    import tempfile

    def _atomic_write_json(path, data):
        """Write JSON atomically: write to temp file, fsync, then rename."""
        dir_name = os.path.dirname(path)
        fd, tmp = tempfile.mkstemp(dir=dir_name, suffix='.tmp')
        with os.fdopen(fd, 'w') as f:
            json.dump(data, f)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)

    # POSIX-ish username pattern. Capitals are accepted here so the check
    # is a no-op for the current FirstUseAuthenticator path; the eventual
    # GitHub OAuth wiring will add `normalize_username = str.lower`
    # so spawned unix accounts end up lowercase by then. The 32-char limit
    # is the practical useradd cap on most distros.
    VALID_USERNAME_RE = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_-]{0,31}$')

    # Names that already exist on a stock Ubuntu 24.04 box and would either
    # collide with system services or grant unintended access. Refuse to
    # spawn into any of them, even if the authenticator hands them to us.
    SYSTEM_USERNAMES = frozenset({
        'root', 'daemon', 'bin', 'sys', 'sync', 'games', 'man', 'lp', 'mail',
        'news', 'uucp', 'proxy', 'www-data', 'backup', 'list', 'irc', 'gnats',
        'nobody', 'systemd-network', 'systemd-resolve', 'systemd-timesync',
        'messagebus', 'sshd', 'tss', 'landscape', 'pollinate', 'fwupd-refresh',
        'usbmux', '_apt', 'tcpdump', 'uuidd', 'systemd-coredump',
        'ubuntu', 'jupyterhub', 'caddy',
    })

    def pre_spawn_hook(spawner):
        username = spawner.user.name

        # Defensive validation. Both checks were absent in the original
        # FirstUseAuthenticator setup; that was tolerable when users picked
        # their own names but becomes a real foot-gun under any external
        # identity provider.
        if not VALID_USERNAME_RE.match(username):
            raise RuntimeError(
                f"refusing to spawn invalid username {username!r}: "
                "must be 1-32 chars matching [a-zA-Z_][a-zA-Z0-9_-]*"
            )
        if username.lower() in SYSTEM_USERNAMES:
            raise RuntimeError(
                f"refusing to spawn system username {username!r}"
            )

        # useradd: exit 0 = created, exit 9 = already exists (idempotent
        # re-spawn after a previous successful login). Anything else is a
        # real failure and we surface it loudly so the spawn error appears
        # in the hub log instead of the user seeing a silent white screen.
        # `--badname` is included now (it's a no-op for current usernames)
        # so the hook is ready for GitHub-OAuth-derived names that may
        # start with a digit, which the default useradd NAME_REGEX rejects.
        result = subprocess.run(
            ['useradd', '--badname', '-m', '-s', '/bin/bash', username],
            capture_output=True,
            text=True,
        )
        if result.returncode not in (0, 9):
            raise RuntimeError(
                f"useradd failed for {username!r} "
                f"(exit {result.returncode}): {result.stderr.strip()}"
            )

        home = os.path.expanduser(f'~{username}')
        marker = os.path.join(home, '.seeded')
        if not os.path.exists(marker):
            # Seed from the user's chosen starter template (default researcher).
            chosen_template = _selected_template(spawner)
            shutil.copytree(
                _template_dir(chosen_template), home, dirs_exist_ok=True
            )
            # Suppress all tips, notices, and onboarding prompts.
            # High counters ensure Claude Code thinks everything has been seen.
            claude_json = {
                'hasCompletedOnboarding': True,
                'numStartups': 100,
                'hasSeenTasksHint': True,
                'hasSeenStashHint': True,
                'hasShownOpus45Notice': True,
                'hasShownOpus46Notice': True,
                'opus1mMergeNoticeSeenCount': 99,
                'ideHintShownCount': 99,
                'voiceNoticeSeenCount': 99,
                'tipsHistory': {str(i): True for i in range(50)},
                'projects': {
                    home: {
                        'hasTrustDialogAccepted': True,
                        'allowedTools': [],
                        'hasCompletedProjectOnboarding': True,
                    }
                }
            }
            # Pre-approve the injected first-party API key so the "Detected a
            # custom API key … use it?" prompt never appears for new users —
            # declining/escaping it strands them at Claude Code's /login even
            # though ANTHROPIC_API_KEY is set. Claude keys the approval on the
            # last 20 chars of the key. No-op on the vertex backend / local dev,
            # where the file is absent (experts then auth however they like).
            if os.path.exists(ANTHROPIC_API_KEY_FILE):
                with open(ANTHROPIC_API_KEY_FILE) as _k:
                    _api_key = _k.read().strip()
                if _api_key:
                    claude_json['customApiKeyResponses'] = {
                        'approved': [_api_key[-20:]],
                        'rejected': [],
                    }
            _atomic_write_json(os.path.join(home, '.claude.json'), claude_json)
            claude_dir = os.path.join(home, '.claude')
            os.makedirs(claude_dir, exist_ok=True)
            settings = {
                'skipDangerousModePermissionPrompt': True,
                'spinnerTipsEnabled': False,
                'feedbackSurveyRate': 0,
            }
            _atomic_write_json(os.path.join(claude_dir, 'settings.json'), settings)
            # Record the chosen template in the marker so go-jupyter-refresh-user
            # can later re-apply the right template to this user.
            with open(marker, 'w') as _m:
                _m.write(chosen_template + '\n')
            subprocess.run(['chown', '-R', f'{username}:{username}', home])

    c.Spawner.pre_spawn_hook = pre_spawn_hook
else:
    # Local dev: no user isolation, runs as current user. Keep
    # FirstUseAuthenticator — PAM needs root and the dev path doesn't
    # need a real auth model. No allowlist gate: a developer running
    # `uv run jupyterhub` on their own laptop is already authenticated by
    # being on the laptop, so a port-9000 hub doesn't need theater.
    c.JupyterHub.authenticator_class = 'firstuseauthenticator.FirstUseAuthenticator'
    c.FirstUseAuthenticator.create_users = True

    c.JupyterHub.spawner_class = 'simple'
    c.SimpleLocalProcessSpawner.home_dir_template = os.path.join(config_dir, 'local-users', '{username}')
    c.Spawner.args = ['--allow-root']

    def pre_spawn_hook_local(spawner):
        username = spawner.user.name
        home = os.path.join(config_dir, 'local-users', username)
        os.makedirs(home, exist_ok=True)
        marker = os.path.join(home, '.seeded')
        if not os.path.exists(marker):
            chosen_template = _selected_template(spawner)
            shutil.copytree(
                _template_dir(chosen_template), home, dirs_exist_ok=True
            )
            with open(marker, 'w') as _m:
                _m.write(chosen_template + '\n')

    c.Spawner.pre_spawn_hook = pre_spawn_hook_local

# Per-user starter-template chooser (shown on first login only — see above).
c.Spawner.options_form = template_options_form
c.Spawner.options_from_form = template_options_from_form

# Open directly into the lab
c.Spawner.default_url = '/lab'

# Log single-user server output for debugging
c.Spawner.debug = True
