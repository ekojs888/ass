#!/usr/bin/env bash
# reward.sh - sistem nilai (reward/punishment)
source "$ASS_LIB/util.sh"
REWARD_FILE="${ASS_DATA}/reward.db"
declare -A REWARD_SCORE

reward_load() {
  [[ -f "$REWARD_FILE" ]] || touch "$REWARD_FILE"
  REWARD_SCORE=()
  while IFS=$'\t' read -r p s t; do
    [[ -z "$p" ]] && continue
    REWARD_SCORE["$p"]="$s"
  done <"$REWARD_FILE"
}
reward_save() {
  : >"$REWARD_FILE"
  for p in "${!REWARD_SCORE[@]}"; do printf "%s\t%s\t%s\n" "$p" "${REWARD_SCORE[$p]}" "$(now_iso)" >>"$REWARD_FILE"; done
}
reward_update() {
  local p="$1" exit="${2:-0}" d=0
  [[ "$exit" -eq 0 ]] && d=1 || d=-1
  local s="${REWARD_SCORE[$p]:-0}"
  s=$((s + d))
  REWARD_SCORE["$p"]="$s"
  reward_save
  if ((s >= 5)); then echo "🏆 Pola '$p' terbukti andal (score=$s)"; fi
  if ((s <= -3)); then echo "⚠️ Pola '$p' sering gagal (score=$s)"; fi
}
reward_get_score() { echo "${REWARD_SCORE[$1]:-0}"; }
