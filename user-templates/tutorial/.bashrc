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

  # What's new — shown only when the news has changed since this user last read
  # it, so a normal session start is unchanged. The "seen" marker deliberately
  # lives OUTSIDE ~/.go-jupyter/news/ because that directory is a hard mirror
  # (rsync --delete) and anything inside it is wiped on every sync.
  _news="$HOME/.go-jupyter/news/NEWS.md"
  _seen="$HOME/.go-jupyter/news-seen"
  if [ -r "$_news" ]; then
    _sum="$(md5sum "$_news" 2>/dev/null | cut -d' ' -f1)"
    if [ "$_sum" != "$(cat "$_seen" 2>/dev/null || true)" ]; then
      echo "  ─── What's new ─────────────────────────────"
      echo ""
      sed 's/^/  /' "$_news"
      echo ""
      mkdir -p "$(dirname "$_seen")" 2>/dev/null || true
      printf '%s' "$_sum" > "$_seen" 2>/dev/null || true
    fi
  fi
  unset _news _seen _sum

  echo ""
  read -r choice
  if [ "$choice" != "t" ] && [ "$choice" != "T" ]; then
    claude --dangerously-skip-permissions
  fi
fi
