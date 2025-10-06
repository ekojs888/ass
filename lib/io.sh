#!/usr/bin/env bash
# io.sh – fungsi bantu baca/tulis
atomic_write_file() {
  local f="$1"
  cat >"${f}.tmp" && mv "${f}.tmp" "$f"
}
append_line_safe() {
  local l="$1" f="$2"
  mkdir -p "$(dirname "$f")"
  grep -qxF "$l" "$f" 2>/dev/null || echo "$l" >>"$f"
}
