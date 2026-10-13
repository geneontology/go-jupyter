export PATH="/usr/local/bin:/opt/go-jupyter/.venv/bin:$PATH"

if [[ $- == *i* ]] && [ -t 0 ]; then
  clear
  echo ""
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║      🤖 GO Agentic AI Workshop           ║"
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

  echo ""
  read -r choice
  if [ "$choice" != "t" ] && [ "$choice" != "T" ]; then
    claude --dangerously-skip-permissions
  fi
fi
