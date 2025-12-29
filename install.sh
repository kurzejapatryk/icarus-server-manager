#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/icarus-server"
SERVICE_NAME="icarus"
SERVICE_DST="/etc/systemd/system/${SERVICE_NAME}.service"
BIN_LINK="/usr/local/bin/icarus-manager"

USER_NAME="icarus"
GROUP_NAME="docker"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo ./install.sh"
    exit 1
  fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_distro() {
  if [ ! -f /etc/os-release ]; then
    echo "Cannot detect OS (missing /etc/os-release)."
    exit 1
  fi
  . /etc/os-release
  case "${ID:-}" in
    debian|ubuntu) ;;
    *)
      echo "Unsupported distro: ${ID:-unknown}. This installer supports Debian/Ubuntu."
      exit 1
      ;;
  esac
}

install_prereqs() {
  echo "[*] Installing prerequisites..."
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release git jq
}

install_docker_if_missing() {
  if have_cmd docker; then
    echo "[*] Docker already installed."
    return 0
  fi

  echo "[*] Installing Docker Engine + docker compose plugin..."
  install -m 0755 -d /etc/apt/keyrings

  . /etc/os-release
  curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} \
    ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

ensure_user() {
  if id "$USER_NAME" >/dev/null 2>&1; then
    echo "[*] User '$USER_NAME' exists."
  else
    echo "[*] Creating user '$USER_NAME'..."
    useradd --system --create-home --shell /bin/bash "$USER_NAME"
  fi

  if getent group "$GROUP_NAME" >/dev/null 2>&1; then
    :
  else
    echo "[*] Creating group '$GROUP_NAME'..."
    groupadd "$GROUP_NAME"
  fi

  echo "[*] Adding '$USER_NAME' to group '$GROUP_NAME'..."
  usermod -aG "$GROUP_NAME" "$USER_NAME"
}

sync_files() {
  echo "[*] Installing files to ${INSTALL_DIR}..."
  mkdir -p "$INSTALL_DIR"
  rsync -a --delete \
    --exclude ".git" \
    --exclude ".github" \
    --exclude "README.md" \
    --exclude "LICENSE" \
    "$REPO_DIR/" "$INSTALL_DIR/"

  chmod +x "${INSTALL_DIR}/icarus-manager.sh" || true
  chmod +x "${INSTALL_DIR}/update.sh" 2>/dev/null || true
  chmod +x "${INSTALL_DIR}/uninstall.sh" 2>/dev/null || true

  mkdir -p "${INSTALL_DIR}/lang"
  mkdir -p "/home/icarus-backups"

  chown -R "$USER_NAME":"$USER_NAME" "$INSTALL_DIR"
  chown -R "$USER_NAME":"$USER_NAME" "/home/icarus-backups" || true
}

ensure_compose_and_env() {
  echo "[*] Ensuring docker-compose.yml and .env..."

  if [ ! -f "${INSTALL_DIR}/docker-compose.yml" ]; then
    if [ -f "${INSTALL_DIR}/docker-compose.yml.example" ]; then
      cp "${INSTALL_DIR}/docker-compose.yml.example" "${INSTALL_DIR}/docker-compose.yml"
      chown "$USER_NAME":"$USER_NAME" "${INSTALL_DIR}/docker-compose.yml"
      echo "    Created docker-compose.yml from example."
    else
      echo "Missing docker-compose.yml.example in ${INSTALL_DIR}."
      exit 1
    fi
  else
    echo "    docker-compose.yml already exists."
  fi

  if [ ! -f "${INSTALL_DIR}/.env" ]; then
    echo ""
    echo "Configuring server settings..."
    read -p "Enter SERVERNAME [Icarus Server]: " servername
    servername=${servername:-"Icarus Server"}

    read -p "Enter JOIN_PASSWORD [changeme]: " join_password
    join_password=${join_password:-"changeme"}

    read -p "Enter ADMIN_PASSWORD [changeme]: " admin_password
    admin_password=${admin_password:-"changeme"}

    cat > "${INSTALL_DIR}/.env" <<EOF
SERVERNAME=$servername
JOIN_PASSWORD=$join_password
ADMIN_PASSWORD=$admin_password
EOF
    chown "$USER_NAME":"$USER_NAME" "${INSTALL_DIR}/.env"
    chmod 600 "${INSTALL_DIR}/.env"
    echo "    Created .env with provided settings."
  else
    echo "    .env already exists."
  fi

  if [ ! -f "${INSTALL_DIR}/.lang" ]; then
    echo "en" > "${INSTALL_DIR}/.lang"
    chown "$USER_NAME":"$USER_NAME" "${INSTALL_DIR}/.lang"
  fi
}

install_service() {
  echo "[*] Installing systemd service..."
  if [ ! -f "${INSTALL_DIR}/systemd/icarus.service" ]; then
    echo "Missing ${INSTALL_DIR}/systemd/icarus.service"
    exit 1
  fi

  cp "${INSTALL_DIR}/systemd/icarus.service" "$SERVICE_DST"
  systemctl daemon-reload
  systemctl enable "$SERVICE_NAME"
}

install_bin_link() {
  echo "[*] Creating command: icarus-manager"
  ln -sf "${INSTALL_DIR}/icarus-manager.sh" "$BIN_LINK"
}

pull_image_optional() {
  echo ""
  read -rp "Pull docker image now? (y/n): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo -u "$USER_NAME" bash -lc "cd '$INSTALL_DIR' && docker compose pull"
  fi
}

start_service_optional() {
  echo ""
  read -rp "Start service now? (y/n): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    systemctl start "$SERVICE_NAME"
  fi
}

final_info() {
  echo ""
  echo "======================================"
  echo "INSTALL COMPLETE"
  echo "======================================"
  echo ""
  echo "Files:"
  echo "  ${INSTALL_DIR}"
  echo ""
  echo "Edit passwords:"
  echo "  sudo nano ${INSTALL_DIR}/.env"
  echo ""
  echo "Control service:"
  echo "  sudo systemctl start|stop|restart ${SERVICE_NAME}"
  echo ""
  echo "Run manager:"
  echo "  icarus-manager"
  echo ""
}

main() {
  need_root
  detect_distro
  install_prereqs
  install_docker_if_missing
  ensure_user
  sync_files
  ensure_compose_and_env
  install_service
  install_bin_link
  pull_image_optional
  start_service_optional
  final_info
}

main "$@"
