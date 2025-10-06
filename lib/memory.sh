#!/usr/bin/env bash
# =======================================================
# memory.sh — Sistem Memori Lapisan Otak
# =======================================================

source "$ASS_LIB/util.sh"
source "$ASS_LIB/io.sh"

declare -A MEM_SHORT MEM_MID MEM_LONG MEM_LAYER MEM_COUNT MEM_TS

DB_MID="${ASS_DATA}/mem_mid.db"
DB_LONG="${ASS_DATA}/mem_long.db"
TPL_FILE="${ASS_CONF}/templates.conf"

# =======================================================
# LOAD MEMORY
# =======================================================
mem_load_all() {
  # Muat mid & long dari file
  for layer in mid long; do
    local f var
    case "$layer" in
      mid)  f="$DB_MID";  var="MEM_MID" ;;
      long) f="$DB_LONG"; var="MEM_LONG" ;;
    esac
    [[ -f "$f" ]] || touch "$f"
    while IFS=$'\t' read -r p c n t; do
      [[ -z "$p" ]] && continue
      [[ "$layer" == mid && $(is_expired "$t" 1) == "yes" ]] && continue
      MEM_LAYER["$p"]="$layer"
      MEM_COUNT["$p"]="${n:-0}"
      MEM_TS["$p"]="${t:-$(now_iso)}"
      eval "$var[\"\$p\"]=\"\$c\""
    done <"$f"
  done

  # Muat template manual (long permanen)
  [[ -f "$TPL_FILE" ]] || touch "$TPL_FILE"
  while IFS='=>' read -r p c; do
    p="$(_trim "$p")"; c="$(_trim "$c")"
    [[ -z "$p" || -z "$c" ]] && continue
    MEM_LONG["$p"]="$c"
    MEM_LAYER["$p"]="long"
  done <"$TPL_FILE"

  log_info "Memori dimuat (short kosong, mid/long aktif)."
}

# =======================================================
# FUNGSI CEK KADALUARSA MID (1 hari)
# =======================================================
is_expired() {
  local ts="$1" days="$2"
  local now_s=$(date -u +%s)
  local ts_s=$(date -d "$ts" +%s 2>/dev/null || echo 0)
  local diff=$(( (now_s - ts_s) / 86400 ))
  [[ $diff -ge $days ]] && echo "yes" || echo "no"
}

# =======================================================
# SIMPAN KE SHORT-TERM MEMORY
# =======================================================
mem_put_short() {
  local p="$1" c="$2"
  local n=$(( ${MEM_COUNT[$p]:-0} + 1 ))

  MEM_SHORT["$p"]="$c"
  MEM_LAYER["$p"]="short"
  MEM_COUNT["$p"]="$n"
  MEM_TS["$p"]="$(now_iso)"

  log_info "Short-term: $p => $c ($n kali)"
  mem_promote_check "$p"
}

# =======================================================
# PROMOSI KE LEVEL LEBIH TINGGI
# =======================================================
mem_promote_check() {
  local p="$1"
  local count="${MEM_COUNT[$p]:-0}"
  local cmd="${MEM_SHORT[$p]:-}"
  local ts="$(now_iso)"
  local tmp

  # Tentukan target DB berdasarkan count
  local target=""
  if (( count >= 20 )); then
    target="$DB_LONG"
    MEM_LONG["$p"]="$cmd"
    MEM_LAYER["$p"]="long"
    log_info "Promosi ke LONG memory: $p"
  elif (( count >= 5 )); then
    target="$DB_MID"
    MEM_MID["$p"]="$cmd"
    MEM_LAYER["$p"]="mid"
    log_info "Promosi ke MID memory: $p"
  else
    return 0
  fi

  # --- Pastikan file target ada ---
  [[ -f "$target" ]] || touch "$target"

  # --- Hapus entri lama untuk key ini ---
  tmp=$(mktemp)
  grep -v -P "^${p}\t" "$target" >"$tmp" 2>/dev/null || true

  # --- Tambahkan entri baru ---
  echo -e "$p\t$cmd\t$count\t$ts" >>"$tmp"
  mv "$tmp" "$target"
}


# =======================================================
# DAPATKAN MEMORY (PRIORITAS)
# =======================================================
mem_get() {
  local p="$1"
  local c=""
  local jm=""

  # 1️⃣ Template manual
  if [[ -n "${MEM_LONG[$p]}" ]]; then
    c="${MEM_LONG[$p]}"
    jm="long";
  elif [[ -n "${MEM_MID[$p]}" ]]; then
    c="${MEM_MID[$p]}"
    jm="mid";
  elif [[ -n "${MEM_SHORT[$p]}" ]]; then
    c="${MEM_SHORT[$p]}"
    jm="short";
  fi

  [[ -z "$c" ]] && return 0

  # Tambah count dan perbarui waktu
  ((MEM_COUNT["$p"]++))
  MEM_TS["$p"]="$(now_iso)"
  mem_promote_check "$p"

  echo "$jm $c"
}

# =======================================================
# SIMPAN TEMPLATE MANUAL
# =======================================================
tpl_add() {
  local p="$(_trim "$1")" c="$(_trim "$2")"
  [[ -z "$p" || -z "$c" ]] && return 1
  tmp=$(mktemp)
  grep -v -P "^${p}[[:space:]]*=>" "$TPL_FILE" >"$tmp" 2>/dev/null || true
  echo "$p => $c" >>"$tmp"
  mv "$tmp" "$TPL_FILE"
  MEM_LONG["$p"]="$c"
  MEM_LAYER["$p"]="long"
  log_info "Template manual ditambahkan: $p => $c"
}
