#!/usr/bin/env bash
# context_stack.sh - stack konteks (riwayat perintah)
source "$ASS_LIB/util.sh"
CONTEXT_STACK_FILE="${ASS_DATA}/context_stack.json"
context_stack_init() { [[ -f "$CONTEXT_STACK_FILE" ]] || echo '[]' >"$CONTEXT_STACK_FILE"; }
context_stack_push() {
  context_stack_init
  jq --arg p "$1" --arg c "$2" --arg t "$3" '. + [{phrase:$p,cmd:$c,topic:$t}] | .[-5:]' \
    "$CONTEXT_STACK_FILE" >"${CONTEXT_STACK_FILE}.tmp" 2>/dev/null || echo '[]' >"${CONTEXT_STACK_FILE}.tmp"
  mv "${CONTEXT_STACK_FILE}.tmp" "$CONTEXT_STACK_FILE"
}
context_stack_show() { jq . "$CONTEXT_STACK_FILE" 2>/dev/null || echo "[]"; }
context_stack_last() { jq -r '.[-1].cmd // ""' "$CONTEXT_STACK_FILE" 2>/dev/null || echo ""; }
context_stack_topic() { jq -r '.[-1].topic // "general"' "$CONTEXT_STACK_FILE" 2>/dev/null || echo "general"; }
