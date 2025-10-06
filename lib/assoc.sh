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


# =======================================================
# AUTO PATTERN LEARNING — sistem belajar pola otomatis 🧠
# =======================================================
declare -gA PATTERN_MEMORY=()

pattern_load() {
  local f="${ASS_CONF}/patterns.conf"
  [[ -f "$f" ]] || touch "$f"

  PATTERN_MEMORY=()
  while IFS='=>' read -r pattern cmd; do
    pattern="$(_trim "$pattern")"
    cmd="$(_trim "$cmd")"
    [[ -z "$pattern" || -z "$cmd" ]] && continue
    PATTERN_MEMORY["$pattern"]="$cmd"
  done <"$f"

  log_info "Pola dimuat: ${#PATTERN_MEMORY[@]} pola."
}

pattern_match() {
  local input="$1"
  local pattern cmd

  # Loop melalui semua kunci (pattern) dalam array asosiatif PATTERN_MEMORY
  for pattern in "${!PATTERN_MEMORY[@]}"; do
    # Cek apakah input cocok dengan pola regex saat ini
    if [[ "$input" =~ $pattern ]]; then
      cmd="${PATTERN_MEMORY[$pattern]}"

      # Ambil jumlah grup tangkapan (capturing groups).
      # ${#BASH_REMATCH[@]} memberikan total elemen, termasuk elemen [0] (match penuh).
      # Jadi, grup tangkapan dimulai dari indeks 1 hingga panjang array - 1.
      local num_groups=${#BASH_REMATCH[@]}

      # Loop untuk mengganti \1, \2, ... dengan nilai yang sesuai dari BASH_REMATCH
      # Dimulai dari i=1 (grup tangkapan pertama)
      for ((i = 1; i < num_groups; i++)); do
        # Pastikan BASH_REMATCH[$i] tidak kosong sebelum melakukan penggantian
        if [[ -n "${BASH_REMATCH[$i]}" ]]; then
          # Mengganti semua kemunculan literal '\i' (misalnya \1) dengan hasilnya
          # Penggantian Bash (//\\$i/${BASH_REMATCH[$i]}) tidak aman jika hasil tangkapan berisi
          # karakter penggantian khusus. Menggunakan sed lebih aman untuk nilai yang tidak terkontrol.
          # Namun, untuk Bash murni dan mencegah subshell, kita gunakan cara ini:
          cmd="${cmd//\\$i/${BASH_REMATCH[$i]}}"
        fi
      done

      echo "$cmd"
      return 0 # Pola ditemukan dan perintah dikembalikan
    fi
  done

  return 1 # Pola tidak ditemukan
}

pattern_match_v2() {
  local input="$1" pattern cmd
  for pattern in "${!PATTERN_MEMORY[@]}"; do
    if [[ "$input" =~ $pattern ]]; then
      cmd="${PATTERN_MEMORY[$pattern]}"
      # ganti \1, \2, dll dengan hasil grup regex
      for ((i = 1; i <= ${#BASH_REMATCH[@]}; i++)); do
        cmd="${cmd//\\$i/${BASH_REMATCH[$i]}}"
      done
      echo "$cmd"
      return 0
    fi
  done
  return 1
}

auto_pattern_learn() {
  local p="$1"  # input asli user (misalnya "ping ke 1.1.1.1")
  local cmd="$2"  # command yang dihubungkan (misalnya "ping -c 2 1.1.1.1")
  local f="${ASS_CONF}/patterns.conf"

  # Normalisasi huruf kecil
  local pattern_input="$(echo "$p" | tr '[:upper:]' '[:lower:]')"
  local pattern_regex=""
  # param_label dihilangkan karena selalu \1 untuk pola yang dibuat di sini

  # Deteksi pola umum — saat ini IP address
  # ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) adalah grup penangkapan PERTAMA (yaitu \1)
  if [[ "$pattern_input" =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    # Mengganti IP address dengan regex grup penangkapan \1
    pattern_regex="${pattern_input//${BASH_REMATCH[1]}/([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)}"
    
    # Bentuk perintah umum berdasarkan cmd
    # Mengganti nilai IP di cmd dengan \1 (grup penangkapan pertama)
    local cmd_general="${cmd//${BASH_REMATCH[1]}/\\1}"

  # Kalau belum ada pola regex, buat default sederhana
  else
    # ubah kata terakhir jadi parameter umum
    # (.+) adalah grup penangkapan PERTAMA (yaitu \1)
    local last_word="${pattern_input##* }"
    pattern_regex="${pattern_input//${last_word}/(.+)}"
    
    # Bentuk perintah umum berdasarkan cmd
    # Mengganti kata terakhir di cmd dengan \1 (grup penangkapan pertama)
    # Ini mengasumsikan kata terakhir di $p adalah parameter yang sama dengan kata terakhir di $cmd
    # Contoh: p="tambah note penting" cmd="echo 'note penting' >> notes.txt"
    # Pola: ^tambah (.+)$ ; cmd_general: echo '\1' >> notes.txt
    local last_word_cmd="${cmd##* }"
    local cmd_general="${cmd//${last_word_cmd}/\\1}"
  fi

  # Tambahkan boundary supaya aman
  pattern_regex="^${pattern_regex}\$"

  # Hindari duplikasi pola yang sama
  # Pastikan $cmd_general sudah terdefinisikan, seharusnya sudah di blok if/else di atas
  if grep -qF "$pattern_regex" "$f" 2>/dev/null; then
    log_info "Pola '$pattern_regex' sudah ada, tidak ditambah ulang."
    return
  fi

  # Simpan pola ke file
  echo "$pattern_regex => $cmd_general" >>"$f"
  log_info "🧩 Pola baru otomatis dibuat: $pattern_regex => $cmd_general"
}

auto_pattern_learn2() {
  local p="$1"  # input asli user
  local cmd="$2"  # command yang dihubungkan
  local f="${ASS_CONF}/patterns.conf"

  # Normalisasi huruf kecil
  local pattern_input="$(echo "$p" | tr '[:upper:]' '[:lower:]')"
  local pattern_regex=""
  local param_label=""

  # Deteksi pola umum — saat ini IP address
  if [[ "$pattern_input" =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
    pattern_regex="${pattern_input//${BASH_REMATCH[1]}/([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)}"
    param_label="\2"
  fi

  # Kalau belum ada pola regex, buat default sederhana
  if [[ -z "$pattern_regex" ]]; then
    # ubah kata terakhir jadi parameter umum
    local last_word="${pattern_input##* }"
    pattern_regex="${pattern_input//${last_word}/(.+)}"
    param_label="\2"
  fi

  # Tambahkan boundary supaya aman
  pattern_regex="^${pattern_regex}\$"

  # Bentuk perintah umum berdasarkan cmd
  # misalnya "ping -c 2 1.1.1.1" -> ganti IP jadi \2
  local cmd_general="$cmd"
  cmd_general="${cmd_general//${BASH_REMATCH[1]}/\\2}"

  # Hindari duplikasi pola yang sama
  if grep -qF "$pattern_regex" "$f" 2>/dev/null; then
    log_info "Pola '$pattern_regex' sudah ada, tidak ditambah ulang."
    return
  fi

  # Simpan pola ke file
  echo "$pattern_regex => $cmd_general" >>"$f"
  log_info "🧩 Pola baru otomatis dibuat: $pattern_regex => $cmd_general"
}
