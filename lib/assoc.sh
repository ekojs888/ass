#!/usr/bin/env bash
# assoc.sh - asosiasi kata & sinonim
source "$ASS_LIB/util.sh"
ASSOC_FILE="${ASS_CONF}/assoc.conf"
declare -A ASSOC_MAP

assoc_load() {
  [[ -f "$ASSOC_FILE" ]] || touch "$ASSOC_FILE"
  ASSOC_MAP=()
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(_trim "$line")"
    [[ -z "$line" ]] && continue
    IFS='=' read -ra parts <<<"$line"
    for w in "${parts[@]}"; do
      for s in "${parts[@]}"; do
        [[ "$w" == "$s" ]] && continue
        ASSOC_MAP["$w"]="$s"
      done
    done
  done <"$ASSOC_FILE"
}
assoc_translate() {
  local input="$*"
  local out=()
  for w in $input; do
    local r="${ASSOC_MAP[$w]}"
    [[ -z "$r" ]] && r="$w"
    out+=("$r")
  done
  echo "${out[*]}"
}

