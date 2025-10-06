#!/usr/bin/env bash
# context.sh - manajemen konteks terakhir
source "$ASS_LIB/util.sh"
CONTEXT_FILE="${ASS_DATA}/context.json"

context_load() {
  [[ -f "$CONTEXT_FILE" ]] || echo '{}' >"$CONTEXT_FILE"
  LAST_PHRASE="$(jq -r '.last_phrase // ""' "$CONTEXT_FILE" 2>/dev/null || echo "")"
  LAST_CMD="$(jq -r '.last_cmd // ""' "$CONTEXT_FILE" 2>/dev/null || echo "")"
  LAST_TOPIC="$(jq -r '.last_topic // ""' "$CONTEXT_FILE" 2>/dev/null || echo "")"
}
context_save() {
  jq -n --arg p "$1" --arg c "$2" --arg t "$3" --arg time "$(now_iso)" \
    '{last_phrase:$p,last_cmd:$c,last_topic:$t,last_time:$time}' >"$CONTEXT_FILE"
}
context_clear() {
  echo '{}' >"$CONTEXT_FILE"
  echo "🧹 Konteks dihapus."
}
context_show() { jq . "$CONTEXT_FILE" 2>/dev/null || echo "{}"; }
context_infer_topic() {
  local i="$1"
  if [[ "$i" =~ ping|ip|network ]]; then
    echo "network"
  elif [[ "$i" =~ folder|file|cd|ls ]]; then
    echo "filesystem"
  elif [[ "$i" =~ update|install|pacman ]]; then
    echo "system"
  else echo "general"; fi
}
