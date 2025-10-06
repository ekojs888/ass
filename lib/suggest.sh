#!/usr/bin/env bash
# suggest.sh - saran tindakan berikutnya
source "$ASS_LIB/util.sh"
source "$ASS_LIB/context_stack.sh"
source "$ASS_LIB/reward.sh"

suggest_next_action() {
  local t="$1"
  reward_load
  echo "💡 Berdasarkan konteks '$t', saran tindakan:"
  case "$t" in
  network)
    ((${REWARD_SCORE["ping 1.1.1.1"]:-0} > 2)) && echo " - ping lagi"
    echo " - cek jaringan (ping, traceroute)"
    ;;
  filesystem)
    echo " - tampilkan isi folder"
    ;;
  system)
    echo " - update sistem (sudo pacman -Syu)"
    ;;
  *)
    echo " - tidak ada saran spesifik"
    ;;
  esac
}
