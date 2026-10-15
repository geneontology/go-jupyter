export PATH="/usr/local/bin:/opt/go-jupyter/.venv/bin:$PATH"

if [[ $- == *i* ]] && [ -t 0 ]; then
  clear
  echo ""
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║      🧬 GO Biocuration Playground        ║"
  echo "  ║                                          ║"
  echo "  ║   Press ENTER to launch Claude Code      ║"
  echo "  ║   Press T then ENTER for a terminal      ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo ""
  echo "  Shared, monitored environment — your activity and usage traces/logs"
  echo "  may be reviewed to analyze and improve the service."

  # What's new — only the entries added since this user last saw the news
  # (entries are the "## " headings in NEWS.md, newest first). The "seen"
  # marker holds the heading of the newest entry already shown; it lives
  # OUTSIDE ~/.go-jupyter/news/ because that directory is a hard mirror
  # (rsync --delete). A marker from the older checksum format, or a heading
  # that has since been pruned from the file, shows the newest entry only.
  _news="$HOME/.go-jupyter/news/NEWS.md"
  _seen="$HOME/.go-jupyter/news-seen"
  if [ -r "$_news" ]; then
    _top="$(grep -m1 '^## ' "$_news" 2>/dev/null || true)"
    _last="$(cat "$_seen" 2>/dev/null || true)"
    case "$_last" in '## '*) ;; *) _last="" ;; esac   # old checksum marker, or none
    [ -z "$_last" ] || grep -qxF -- "$_last" "$_news" 2>/dev/null || _last=""   # pruned
    if [ -n "$_top" ] && [ "$_top" != "$_last" ]; then
      echo "  ─── What's new ─────────────────────────────"
      echo ""
      awk -v last="$_last" '
        /^## / { n++; if (last != "" && $0 == last) exit; if (last == "" && n > 1) exit }
        n >= 1 && $0 != "---" { print "  " $0 }' "$_news"
      echo "  (all announcements: ~/.go-jupyter/news/NEWS.md)"
      echo ""
      mkdir -p "$(dirname "$_seen")" 2>/dev/null || true
      printf '%s' "$_top" > "$_seen" 2>/dev/null || true
    fi
  fi
  unset _news _seen _top _last

  # Skills the hub set aside: a canonical skill (go-skills, go-ontology) took the
  # name of a copy in ~/.claude/skills; the copy is kept. Shown once per event.
  if [ -e "$HOME/.go-jupyter/skill-overrides/.unseen" ]; then
    echo "  ─── Skills set aside ───────────────────────"
    echo "  A canonical skill now takes the place of a copy you had in ~/.claude/skills."
    echo "  Your copy is kept under ~/.go-jupyter/skill-overrides/ (see its README)."
    echo "  To get your change into the canonical skill, ask Claude to propose it to"
    echo "  go-skills as an issue or a pull request."
    echo ""
    rm -f "$HOME/.go-jupyter/skill-overrides/.unseen" 2>/dev/null || true
  fi
  # Your own skills: real directories in ~/.claude/skills (not links into the
  # hub's checkouts, not the template's own). Named so the way to share them is known.
  _tmpl="$(head -n1 "$HOME/.seeded" 2>/dev/null | tr -d '[:space:]')"; [ -n "$_tmpl" ] || _tmpl=researcher
  _personal=""
  for _d in "$HOME"/.claude/skills/*/; do
    [ -d "$_d" ] && [ -f "$_d/SKILL.md" ] || continue
    case "$(readlink "${_d%/}" 2>/dev/null)" in /var/lib/go-jupyter/skill-sources/*) continue ;; esac
    [ -d "/opt/go-jupyter/user-templates/$_tmpl/.claude/skills/$(basename "$_d")" ] && continue
    _n="$(basename "$_d")"; _canon=""
    for _c in /var/lib/go-jupyter/skill-sources/*/skills/"$_n" /var/lib/go-jupyter/skill-sources/*/.claude/skills/"$_n"; do [ -d "$_c" ] && _canon=1; done
    [ -n "$_canon" ] && continue
    _personal="$_personal $_n"
  done
  if [ -n "$_personal" ]; then
    echo "  Your own skills (not in go-skills):$_personal"
    echo "  To share one with every curator, ask Claude to propose it to go-skills."
    echo ""
  fi
  unset _tmpl _personal _d _n _c _canon

  echo ""
  read -r choice
  if [ "$choice" != "t" ] && [ "$choice" != "T" ]; then
    claude --dangerously-skip-permissions
  fi
fi
