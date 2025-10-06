ASS_CONF="./config"

# =======================================================
# templates.sh — sistem template manual
# =======================================================

# Fungsi trim universal
_trim() {
  local str="$*"
  str="${str#"${str%%[![:space:]]*}"}"  # hapus spasi di depan
  str="${str%"${str##*[![:space:]]}"}"  # hapus spasi di belakang
  printf '%s' "$str"
}

# Fungsi untuk memuat template manual
tpl_load() {
  local f="${ASS_CONF}/templates.conf"
  [[ -f "$f" ]] || touch "$f"

  # deklarasi associative array global
  declare -gA TPL_CMD=()

  while IFS='=>' read -r p c; do
    # Trim kiri-kanan dan abaikan baris kosong
    p="$(_trim "$p")"
    c="$(_trim "$c")"
    [[ -z "$p" || -z "$c" ]] && continue

    TPL_CMD["$p"]="$c"
  done < <(grep -v '^[[:space:]]*$' "$f")

}


tpl_load;

echo  "${TPL_CMD["cek ip"]}";
