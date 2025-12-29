#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/opt/icarus-server"
SERVICE_NAME="icarus"
SERVICE_DST="/etc/systemd/system/${SERVICE_NAME}.service"
BIN_LINK="/usr/local/bin/icarus-manager"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo ./uninstall.sh"
    exit 1
  fi
}

main() {
  need_root

  echo "[*] Stopping service (if running)..."
  systemctl stop "$SERVICE_NAME" 2>/dev/null || true
  systemctl disable "$SERVICE_NAME" 2>/dev/null || true

  echo "[*] Removing systemd unit..."
  rm -f "$SERVICE_DST"
  systemctl daemon-reload

  echo "[*] Removing command link..."
  rm -f "$BIN_LINK"

  echo ""
  read -rp "Remove install dir (${INSTALL_DIR})? (y/n): " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$INSTALL_DIR"
    echo "Removed: $INSTALL_DIR"
  else
    echo "Kept: $INSTALL_DIR"
  fi

  echo ""
  read -rp "Remove backups dir (/home/icarus-backups)? (y/n): " ans2
  if [[ "$ans2" =~ ^[Yy]$ ]]; then
    rm -rf /home/icarus-backups
    echo "Removed: /home/icarus-backups"
  else
    echo "Kept: /home/icarus-backups"
  fi

  echo ""
  read -rp "Remove docker volumes (data/game)? This deletes world data! (y/n): " ans3
  if [[ "$ans3" =~ ^[Yy]$ ]]; then
    if [ -f "${INSTALL_DIR}/docker-compose.yml" ]; then
      (cd "$INSTALL_DIR" && docker compose down -v) || true
    else
      echo "docker-compose.yml not found; skipping docker compose down -v"
    fi
    echo "Volumes removed (if compose existed)."
  else
    echo "Volumes kept."
  fi

  echo ""
  echo "[*] Uninstall complete."
}

main "$@"
