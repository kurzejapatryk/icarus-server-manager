#!/bin/bash
VERSION="0.1.0"

SERVICE="icarus"
CONTAINER="icarus-dedicated"

# docker compose project dir (tam gdzie docker-compose.yml)
COMPOSE_DIR="/opt/icarus-server"

# env file with server settings
ENV_FILE="${COMPOSE_DIR}/.env"

# volume z danymi świata (wg Twojego compose: data:)
WORLD_VOLUME="data"

BACKUP_DIR="/home/icarus-backups"
TIMEOUT=120
INTERVAL=2

# ---------------------------
# i18n (language packs)
# ---------------------------
LANG_DIR="${COMPOSE_DIR}/lang"
LANG_STATE_FILE="${COMPOSE_DIR}/.lang"
LANG_CODE="${LANG_CODE:-en}"   # można też ustawić env: LANG_CODE=pl ./icarus-manager.sh

declare -A T

t() {
  local k="$1"
  echo "${T[$k]:-$k}"
}

load_language() {
  # jeśli jest zapisany wybór, to go użyj
  if [ -f "$LANG_STATE_FILE" ]; then
    LANG_CODE="$(cat "$LANG_STATE_FILE" 2>/dev/null | tr -d '[:space:]')"
  fi

  # fallback
  [ -z "$LANG_CODE" ] && LANG_CODE="en"

  local file="${LANG_DIR}/${LANG_CODE}.sh"
  if [ ! -f "$file" ]; then
    # fallback do en
    LANG_CODE="en"
    file="${LANG_DIR}/en.sh"
  fi

  # shellcheck source=/dev/null
  source "$file"
}

save_language() {
  echo "$LANG_CODE" > "$LANG_STATE_FILE"
}

change_language_menu() {
  while true; do
    clear
    echo "======================================"
    echo "              $(t LANG_TITLE)              "
    echo "======================================"
    echo ""
    echo "  [1]  $(t LANG_OPT_EN)"
    echo "  [2]  $(t LANG_OPT_PL)"
    echo ""
    echo "  [0]  $(t BACK)"
    echo ""

    read -rp "$(t SELECT_OPTION): " x
    echo ""

    case "$x" in
      1)
        LANG_CODE="en"
        save_language
        load_language
        echo "$(t LANG_SAVED)"
        echo ""
        read -rp "$(t PRESS_ENTER_GENERIC)" _
        return 0
        ;;
      2)
        LANG_CODE="pl"
        save_language
        load_language
        echo "$(t LANG_SAVED)"
        echo ""
        read -rp "$(t PRESS_ENTER_GENERIC)" _
        return 0
        ;;
      0) return 0 ;;
      *) echo "$(t INVALID_OPTION)"; sleep 1 ;;
    esac
  done
}

# Load language at startup
load_language

ensure_backup_dir() {
  mkdir -p "$BACKUP_DIR"
}

ensure_env_file() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "$(t ENV_NOT_FOUND): $ENV_FILE"
    echo "$(t ENV_CREATE_HINT):"
    echo "  SERVERNAME=KMPK"
    echo "  JOIN_PASSWORD=..."
    echo "  ADMIN_PASSWORD=..."
    return 1
  fi
  return 0
}

get_env() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | head -n 1 | cut -d= -f2- || true
}

set_env() {
  local key="$1"
  local value="$2"

  if grep -qE "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*$|${key}=${value}|g" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

prompt_set() {
  local key="$1"
  local label="$2"
  local hide="${3:-0}"
  local current newval

  current="$(get_env "$key")"

  echo "$label"
  echo "$(t CURRENT): ${current:-<not set>}"

  if [ "$hide" = "1" ]; then
    read -rsp "$(t NEW_VALUE): " newval
    echo ""
  else
    read -rp "$(t NEW_VALUE): " newval
  fi

  if [ -n "$newval" ]; then
    set_env "$key" "$newval"
    echo "$(t SAVED): $key $(t UPDATED)."
  else
    echo "$(t NO_CHANGE)."
  fi
  echo ""
}

edit_settings_menu() {
  ensure_env_file || { read -rp "$(t PRESS_ENTER_GENERIC)" _; return 1; }

  while true; do
    clear
    echo "======================================"
    echo "           $(t SETTINGS_TITLE)          "
    echo "======================================"
    echo ""
    echo "  [1]  $(t SET_SERVERNAME)"
    echo "  [2]  $(t SET_JOINPASS)"
    echo "  [3]  $(t SET_ADMINPASS)"
    echo "  [4]  $(t SET_SHOW)"
    echo ""
    echo "  [9]  $(t SET_APPLY)"
    echo "  [0]  $(t BACK)"
    echo ""

    read -rp "$(t SELECT_OPTION): " sopt
    echo ""

    case $sopt in
      1) prompt_set "SERVERNAME" "$(t SERVERNAME_LABEL)" 0 ;;
      2) prompt_set "JOIN_PASSWORD" "$(t JOINPASS_LABEL)" 1 ;;
      3) prompt_set "ADMIN_PASSWORD" "$(t ADMINPASS_LABEL)" 1 ;;
      4)
        echo "$(t ENV_CURRENT): $ENV_FILE"
        echo "--------------------------------------"
        echo "SERVERNAME=$(get_env SERVERNAME)"
        echo "JOIN_PASSWORD=<hidden>"
        echo "ADMIN_PASSWORD=<hidden>"
        echo "--------------------------------------"
        echo ""
        read -rp "$(t PRESS_ENTER_GENERIC)" _
        ;;
      9)
        echo "$(t APPLY_REQUIRES_RESTART)"
        read -rp "$(t RESTART_NOW): " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
          sudo systemctl restart "$SERVICE"
          wait_for_server
        fi
        ;;
      0) return 0 ;;
      *) echo "$(t INVALID_OPTION)"; sleep 1 ;;
    esac
  done
}

is_server_running() {
  systemctl is-active --quiet "$SERVICE"
}

wait_for_server() {
  echo "$(t WAITING)"
  echo ""

  elapsed=0
  while [ $elapsed -lt $TIMEOUT ]; do
    if systemctl is-active --quiet "$SERVICE" \
       && docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
      echo "$(t RUNNING)"
      echo ""
      systemctl status "$SERVICE" --no-pager
      return 0
    fi

    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
    echo -n "."
  done

  echo ""
  echo "$(t TIMEOUT)"
  echo ""
  systemctl status "$SERVICE" --no-pager
  return 1
}

show_container_logs() {
  if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "$(t CONTAINER_NOT_FOUND)"
    echo "$(t TIP_START_FIRST)"
    return 1
  fi

  echo "$(t LOGS_HINT)"
  echo ""

  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "$(t LOGS_NOT_RUNNING)"
    echo "---------------------------------------------"
    docker logs --tail 200 "$CONTAINER"
    echo "---------------------------------------------"
    return 0
  fi

  docker logs -f "$CONTAINER"
}

backup_world() {
  ensure_backup_dir

  if is_server_running; then
    echo "$(t BACKUP_STOPPING_FOR_CONSISTENCY)"
    sudo systemctl stop "$SERVICE"
    echo ""
  fi

  ts="$(date +%Y-%m-%d_%H-%M-%S)"
  outfile="$BACKUP_DIR/icarus_world_${ts}.tar.gz"

  echo "$(t BACKUP_CREATING)"
  echo "  $(t BACKUP_VOLUME) : $WORLD_VOLUME"
  echo "  $(t BACKUP_OUTPUT) : $outfile"
  echo ""

  cd "$COMPOSE_DIR" || { echo "$(t CANNOT_CD) $COMPOSE_DIR"; return 1; }

  actual_vol="$(docker volume ls --format '{{.Name}}' | grep -E "(_|^)data$" | head -n 1)"
  if [ -z "$actual_vol" ]; then
    proj="$(basename "$COMPOSE_DIR")"
    actual_vol="${proj}_data"
  fi

  if docker run --rm \
      -v "${actual_vol}:/src:ro" \
      -v "${BACKUP_DIR}:/backup" \
      alpine:3.20 \
      sh -c "cd /src && tar -czf \"/backup/$(basename "$outfile")\" ."; then
    echo ""
    echo "$(t BACKUP_CREATED)"
  else
    echo ""
    echo "$(t BACKUP_FAILED)"
    return 1
  fi

  echo ""
  read -rp "$(t START_NOW): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo systemctl start "$SERVICE"
    wait_for_server
  fi
}

restore_world() {
  ensure_backup_dir

  mapfile -t backups < <(ls -1t "$BACKUP_DIR"/icarus_world_*.tar.gz 2>/dev/null)

  if [ ${#backups[@]} -eq 0 ]; then
    echo "$(t NO_BACKUPS): $BACKUP_DIR"
    return 1
  fi

  echo "$(t RESTORE_AVAILABLE)"
  echo ""
  i=1
  for f in "${backups[@]}"; do
    echo "  [$i] $(basename "$f")"
    i=$((i+1))
  done
  echo ""
  read -rp "$(t RESTORE_SELECT): " n

  if [ "$n" = "0" ]; then
    echo "$(t CANCELLED)"
    return 0
  fi

  if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt ${#backups[@]} ]; then
    echo "$(t RESTORE_INVALID)"
    return 1
  fi

  chosen="${backups[$((n-1))]}"

  echo ""
  echo "$(t RESTORE_YOU_ARE_ABOUT):"
  echo "  $(basename "$chosen")"
  echo ""
  echo "$(t RESTORE_WARNING)"
  read -rp "$(t RESTORE_CONFIRM): " confirm
  if [ "$confirm" != "YES" ]; then
    echo "$(t CANCELLED)"
    return 0
  fi

  if is_server_running; then
    echo ""
    echo "$(t RESTORE_STOPPING)"
    sudo systemctl stop "$SERVICE"
  fi

  cd "$COMPOSE_DIR" || { echo "$(t CANNOT_CD) $COMPOSE_DIR"; return 1; }

  actual_vol="$(docker volume ls --format '{{.Name}}' | grep -E "(_|^)data$" | head -n 1)"
  if [ -z "$actual_vol" ]; then
    proj="$(basename "$COMPOSE_DIR")"
    actual_vol="${proj}_data"
  fi

  echo ""
  echo "$(t RESTORE_TO_VOL): $actual_vol"
  echo ""

  if docker run --rm \
      -v "${actual_vol}:/dst" \
      -v "${BACKUP_DIR}:/backup:ro" \
      alpine:3.20 \
      sh -c "rm -rf /dst/* /dst/.[!.]* /dst/..?* 2>/dev/null; cd /dst && tar -xzf \"/backup/$(basename "$chosen")\""; then
    echo ""
    echo "$(t RESTORE_DONE)"
  else
    echo ""
    echo "$(t RESTORE_FAILED)"
    return 1
  fi

  echo ""
  read -rp "$(t START_NOW): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo systemctl start "$SERVICE"
    wait_for_server
  fi
}

while true; do
  clear
  echo "======================================"
  echo "        $(t MENU_TITLE)          "
  echo "======================================"
  echo ""
  echo "  [1]  $(t MENU_START)"
  echo "  [2]  $(t MENU_STOP)"
  echo "  [3]  $(t MENU_RESTART)"
  echo ""
  echo "  [4]  $(t MENU_STATUS)"
  echo "  [5]  $(t MENU_LOGS)"
  echo ""
  echo "  [6]  $(t MENU_BACKUP)"
  echo "  [7]  $(t MENU_RESTORE)"
  echo ""
  echo "  [8]  $(t MENU_SETTINGS)"
  echo "  [9]  $(t MENU_LANG)"
  echo ""
  echo "  [0]  $(t MENU_EXIT)"
  echo ""
  echo "--------------------------------------"
  echo "  2025  Patryk Kurzeja"
  echo "  https://github.com/kurzejapatryk/"
  echo "--------------------------------------"
  echo ""

  read -rp "$(t SELECT_OPTION): " opt
  echo ""

  case $opt in
    1)
      sudo systemctl start "$SERVICE"
      wait_for_server
      ;;
    2)
      sudo systemctl stop "$SERVICE"
      echo "$(t STOPPED)"
      ;;
    3)
      sudo systemctl restart "$SERVICE"
      wait_for_server
      ;;
    4)
      systemctl status "$SERVICE" --no-pager
      ;;
    5)
      show_container_logs
      ;;
    6)
      backup_world
      ;;
    7)
      restore_world
      ;;
    8)
      edit_settings_menu
      ;;
    9)
      change_language_menu
      ;;
    0)
      echo "$(t EXITING)"
      exit 0
      ;;
    *)
      echo "$(t INVALID_OPTION)"
      ;;
  esac

  echo ""
  read -rp "$(t PRESS_ENTER): " _
done
