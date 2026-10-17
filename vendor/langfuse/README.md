# vendor/langfuse

`langfuse_hook.py` is Langfuse's own Claude Code hook, copied here unmodified
so that `scripts/go-jupyter-trace-sync` can run it as root against the archived
transcripts (go-jupyter #28). It is not installed as a Claude Code plugin and
never runs inside a curator's session.

- Source repository: https://github.com/langfuse/Claude-Observability-Plugin,
  file `hooks/langfuse_hook.py`
- Commit: `b5b7cc364996467e856dc17575b5674f4799ad87` ("chore: release v1.2.1",
  2026-10-06)
- Vendored: 2026-10-16
- License: MIT (Langfuse GmbH); the repository's `LICENSE` at the same commit is
  `LICENSE` next to this file
- sha256 of `langfuse_hook.py` as downloaded:
  `6bfe30ebef382f3f7f1884a97c1783dc2a47ae8413ae5e10877f919846c1e698`
- Modifications: none. Do not edit the file here; update it by replacing it at
  a newer commit and recording the new commit, date and sha256 above.

The script's PEP 723 header declares `langfuse>=4.7,<5`; the same range is in
`pyproject.toml` so the project venv (`/opt/go-jupyter/.venv/bin/python` on the
box) can run it. It reads its configuration from the environment
(`LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY`, `LANGFUSE_BASE_URL`,
`LANGFUSE_USER_ID`, `CC_LANGFUSE_STATE_DIR`, `CC_LANGFUSE_TRACE_TAGS`,
`CC_LANGFUSE_CAPTURE_IMAGES`, `CC_LANGFUSE_DEBUG`), takes a Claude Code hook
payload on stdin (`session_id`, `transcript_path`, `hook_event_name`), keeps a
byte offset per transcript in `langfuse_state.json` under the state dir so a
rerun emits nothing new, and logs to `langfuse_hook.log` there. It is
fail-open: a missing key, an unreachable host or an internal error is logged
and the exit status is still 0.

Refresh at a newer commit (then update the commit, date and sha256 above):

```sh
gh api 'repos/langfuse/Claude-Observability-Plugin/contents/hooks/langfuse_hook.py?ref=<commit>' -H 'Accept: application/vnd.github.raw' > vendor/langfuse/langfuse_hook.py
```
