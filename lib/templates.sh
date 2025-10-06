#!/usr/bin/env bash
# templates.sh - manajemen template pola jangka panjang
source "$ASS_LIB/util.sh"
declare -A TPL_CMD

# Fungsi untuk memuat template manual
tpl_load() {
  local f="${ASS_CONF}/templates.conf"
  [[ -f "$f" ]] || touch "$f"

  # associative array global
  declare -gA TPL_CMD=()

  while IFS= read -r line; do
    # lewati baris kosong atau komentar
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "${line#"${line%%[![:space:]]*}"}" == "#" ]] && continue

    # harus mengandung '=>'
    [[ "$line" != *"=>"* ]] && continue

    # split pada first '=>'
    local p="${line%%=>*}"
    local c="${line#*=>}"

    # trim
    p="$(_trim "$p")"
    c="$(_trim "$c")"

    # hapus satu atau lebih '>' awalan + trim lagi (jika user menulis "> ip a" atau ">> ip a")
    while [[ "${c:0:1}" == '>' ]]; do
      c="${c#>}"
      c="$(_trim "$c")"
    done

    # kalau kosong setelah sanitasi, lewati
    [[ -z "$p" || -z "$c" ]] && continue

    TPL_CMD["$p"]="$c"
  done <"$f"

  log_info "Template manual dimuat: ${#TPL_CMD[@]} entri."
}


tpl_add() {
  local p="$(_trim "$1")"
  local c="$(_trim "$2")"
  local f="${ASS_CONF}/templates.conf"

  # Pastikan key dan command tidak kosong
  [[ -z "$p" || -z "$c" ]] && {
    log_warn "Template tidak valid: key atau command kosong"
    return 1
  }

  # Hapus entri lama (kalau sudah ada) sebelum menambah baru
  tmpfile=$(mktemp)
  grep -v -P "^${p}[[:space:]]*=>" "$f" >"$tmpfile" 2>/dev/null || true
  echo "$p => $c" >>"$tmpfile"
  mv "$tmpfile" "$f"

  # Simpan di memori runtime
  TPL_CMD["$p"]="$c"

  log_info "Template baru: $p => $c"
}

tpl_remove() {
  local p="$1"
  grep -v -F "$p" "${ASS_CONF}/templates.conf" >"${ASS_CONF}/tmp"
  mv "${ASS_CONF}/tmp" "${ASS_CONF}/templates.conf"
  unset TPL_CMD["$p"]
  log_info "Template dihapus: $p"
}
