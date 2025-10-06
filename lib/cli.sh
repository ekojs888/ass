#!/usr/bin/env bash
# cli.sh - antarmuka utama pengguna
source "$ASS_LIB/assoc.sh"
source "$ASS_LIB/context.sh"
source "$ASS_LIB/context_stack.sh"
source "$ASS_LIB/reward.sh"

cli_loop() {
  while true; do
    read -rp "ASS> " input
    input="$(_trim "$input")"
    [[ -z "$input" ]] && continue
    case "$input" in
    exit | quit)
      echo "👋 Sampai jumpa."
      break
      ;;
    bantuan)
      echo "Perintah: bantuan, list-short, list-mid, list-long, reflex on|off, konteks, ulang"
      ;;
    list-short) cat "${ASS_DATA}/mem_short.db" 2>/dev/null || echo "(kosong)" ;;
    list-mid) cat "${ASS_DATA}/mem_mid.db" 2>/dev/null || echo "(kosong)" ;;
    list-long) cat "${ASS_CONF}/templates.conf" 2>/dev/null || echo "(kosong)" ;;
    reflex\ on)
      ASS_REFLEX_SESSION=true
      echo "⚡ Mode refleks aktif."
      ;;
    reflex\ off)
      ASS_REFLEX_SESSION=false
      echo "⚡ Mode refleks dimatikan."
      ;;
    konteks) context_show ;;
    ulang | lagi)
      last="$(context_stack_last)"
      [[ -n "$last" ]] && {
        echo "🔁 Ulang: $last"
        bash -ic "$last"
      } || echo "Tidak ada."
      ;;
    *) decide_and_execute "$input" ;;
    esac
  done
}
