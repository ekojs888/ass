#!/usr/bin/env bash
# util.sh – fungsi dasar berbahasa Indonesia
_trim() {
  local str="$*"
  str="${str#"${str%%[![:space:]]*}"}"  # hapus spasi di depan
  str="${str%"${str##*[![:space:]]}"}"  # hapus spasi di belakang
  printf '%s' "$str"
}
now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

LOGFILE="${ASS_DATA:-./data}/decisions.log"
log_info() { echo "[$(now_iso)] INFO:  $*" >>"$LOGFILE"; }
log_warn() { echo "[$(now_iso)] WARN:  $*" >>"$LOGFILE"; }
log_error() { echo "[$(now_iso)] ERROR: $*" >>"$LOGFILE"; }

# ======= Konfigurasi Mode Refleks =======
REFLEX_CONF="${ASS_CONF:-./config}/reflex.conf"
ASS_REFLEX_ENABLED=false
ASS_REFLEX_THRESHOLD=5
declare -a ASS_REFLEX_WHITELIST ASS_REFLEX_BLACKLIST

load_reflex_conf() {
  [[ -f "$REFLEX_CONF" ]] || {
    mkdir -p "$(dirname "$REFLEX_CONF")"
    cat >"$REFLEX_CONF" <<'RCF'
enabled=false
threshold=5
# whitelist
ping
xdg-open
ls
cat
# blacklist
rm -rf
shutdown
reboot
dd
RCF
  }
  ASS_REFLEX_WHITELIST=()
  ASS_REFLEX_BLACKLIST=("rm -rf" "shutdown" "reboot" "dd")
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(_trim "$line")"
    [[ -z "$line" ]] && continue
    case "$line" in
    enabled=*) ASS_REFLEX_ENABLED="${line#enabled=}" ;;
    threshold=*) ASS_REFLEX_THRESHOLD="${line#threshold=}" ;;
    *) [[ "$line" != *=* ]] && ASS_REFLEX_WHITELIST+=("$line") ;;
    esac
  done <"$REFLEX_CONF"
}

is_cmd_whitelisted() {
  local cmd="${*,,}"
  for b in "${ASS_REFLEX_BLACKLIST[@]}"; do [[ "$cmd" == *"$b"* ]] && return 1; done
  for w in "${ASS_REFLEX_WHITELIST[@]}"; do [[ "$cmd" == *"$w"* ]] && return 0; done
  return 1
}
