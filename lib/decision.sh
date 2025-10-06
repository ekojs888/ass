#!/usr/bin/env bash
# ===========================================================
# decision.sh — Logika pengambilan keputusan otak Aksan Smart Shell 🧠
# ===========================================================
source "$ASS_LIB/util.sh"
source "$ASS_LIB/memory.sh"
source "$ASS_LIB/templates.sh"
source "$ASS_LIB/context.sh"
source "$ASS_LIB/context_stack.sh"
source "$ASS_LIB/reward.sh"
source "$ASS_LIB/assoc.sh"
source "$ASS_LIB/pattern.sh"

rule_load() { [[ -f "${ASS_CONF}/rules.conf" ]] || touch "${ASS_CONF}/rules.conf"; }

# ===========================================================
# Fungsi utama — pengambilan keputusan
# ===========================================================
decide_and_execute() {
  local input="$*"
  local cmd="" layer="" count ts

  # -----------------------------------------------------------
  # 1️⃣ Deteksi kondisi “kalau” atau “jika”
  # -----------------------------------------------------------
  if [[ "$input" =~ (kalau|jika)[[:space:]]+(.+),[[:space:]]+(.*) ]]; then
    local cond="${BASH_REMATCH[2]}" act="${BASH_REMATCH[3]}"
    echo "🧩 Deteksi kondisi: '$cond' → '$act'"
    if evaluate_condition "$cond"; then
      echo "✅ Kondisi terpenuhi, menjalankan: $act"
      bash -ic "$act"
      log_info "Kondisi '$cond' sukses"
    else
      echo "⚠️ Kondisi tidak terpenuhi."
      log_warn "Kondisi '$cond' gagal"
    fi
    return
  fi

  # -----------------------------------------------------------
  # 2️⃣ Translasi sinonim (dari assoc)
  # -----------------------------------------------------------
  input="$(assoc_translate "$input")"

  echo "input : $input"
  echo "template :  ${TPL_CMD[$input]}"

  # -----------------------------------------------------------
  # 3️⃣ Cek memori berdasarkan prioritas otak manusia
  # -----------------------------------------------------------

  # Template manual (paling tinggi)
  if [[ -n "${TPL_CMD[$input]}" ]]; then
    layer="template"
    cmd="${TPL_CMD[$input]}"
  elif [[ -n "${MEM_LONG[$input]}" ]]; then
    layer="long"
    cmd="${MEM_LONG[$input]}"
  elif [[ -n "${MEM_MID[$input]}" ]]; then
    layer="mid"
    cmd="${MEM_MID[$input]}"
  elif [[ -n "${MEM_SHORT[$input]}" ]]; then
    layer="short"
    cmd="${MEM_SHORT[$input]}"
  else
    # =======================================================
    # 🔍 1️⃣ Coba deteksi pola (pattern recognition)
    # =======================================================
    local pattern_cmd
    pattern_cmd="$(pattern_match "$input")"

    pattern_cmd="$(_trim "$pattern_cmd")"
    pattern_cmd="${pattern_cmd#>}"

    echo "input : $input";
    echo "pattern cmd : $pattern_cmd";
    
    if [[ -n "$pattern_cmd" ]]; then
      cmd=$pattern_cmd;
      layer="pola"
    fi
  fi


  # -----------------------------------------------------------
  # 4️⃣ Jika belum dikenal sama sekali
  # -----------------------------------------------------------
  echo "cmd : $cmd"
  
  if [[ -z "$cmd" ]]; then
    echo "🤔 Belum dikenal: '$input'"
    read -rp "Masukkan perintah Linux untuk frasa ini: " cmd
    cmd="$(_trim "$cmd")"
    cmd="${cmd#>}"
    
    [[ -z "$cmd" ]] && { echo "❌ Dibatalkan."; return; }

    mem_put_short "$input" "$cmd"

    echo "cmd : $cmd"
    echo "short memory id $input : ${MEM_SHORT[$input]}";

    read -rp "Jalankan? (y/n): " act
    act="${act,,}"
    case "$act" in
      y | '')
        bash -ic "$cmd"
        reward_update "$input" $?
        context_stack_push "$input" "$cmd" "$(context_infer_topic "$input")"
        suggest_next_action "$(context_stack_topic)"
        ;;
      n | *)
        echo "Batal."
        ;;
    esac

    #belajar mengenal polda
    auto_pattern_learn "$input" "$cmd"
    return
  fi

  # -----------------------------------------------------------
  # 5️⃣ Kalau ditemukan
  # -----------------------------------------------------------
  cmd="$(_trim "$cmd")"
  cmd="${cmd#>}"

  count="${MEM_COUNT[$input]:-0}"
  ts="${MEM_TS[$input]:-$(now_iso)}"

  echo "🔍 Ditemukan di ${layer^^} memory → $cmd (dipakai $count kali)"
  read -rp "Jalankan? (y/e/n): " act
  act="${act,,}"

  pattern_feedback "$input" "$act"

  case "$act" in
    y | '')
      bash -ic "$cmd"
      reward_update "$input" $?

      ((MEM_COUNT["$input"]++))
      MEM_TS["$input"]="$(now_iso)"
      mem_promote_check "$input"

      context_stack_push "$input" "$cmd" "$(context_infer_topic "$input")"
      
      ;;
    e)
      read -rp "Perintah baru: " new
      tpl_add "$input" "$new"
      ;;
    n)
      echo "Batal."
      ;;
    *)
      echo "❌ Tidak dikenali."
      ;;
  esac
}

# ===========================================================
# Evaluasi kondisi sederhana
# ===========================================================
evaluate_condition() {
  [[ "$1" =~ ping ]] && ping -c1 8.8.8.8 &>/dev/null
}
