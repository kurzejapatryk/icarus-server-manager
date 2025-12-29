#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="/opt/icarus-server"
SERVICE_NAME="icarus-server-manager"
USER_NAME="kurzejapatryk"

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo ./update.sh"
    exit 1
  fi
}

main() {
  need_root

  if [ ! -d "$INSTALL_DIR/.git" ]; then
    echo "No git repo found in $INSTALL_DIR."
    echo "If you installed via git clone into /opt/icarus-server, run update there."
    exit 1
  fi

  echo "[*] Updating repo..."
  cd "$INSTALL_DIR"
  git pull --ff-only

  echo "[*] Pulling docker image..."
  sudo -u "$USER_NAME" bash -lc "cd '$INSTALL_DIR' && docker compose pull"

  echo "[*] Restarting service..."
  systemctl restart "$SERVICE_NAME"

  echo "[*] Done."
}

main "$@"
