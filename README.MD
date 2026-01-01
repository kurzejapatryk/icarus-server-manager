# Icarus Server Manager (Docker Compose)

A Docker Compose-based dedicated server manager for the game Icarus. Enables easy installation, management, and backup of the game server.

## Features

- 🚀 **Easy Installation** - automatic installer for Debian/Ubuntu systems
- 🐳 **Docker Compose** - containerization for isolation and easy management
- 🔧 **Management Interface** - user-friendly text interface for server control
- 🌍 **Multilingual** - support for Polish and English languages
- 💾 **Backups** - automatic creation and restoration of world backups
- 🔄 **Updates** - easy server updates
- ⚙️ **Configuration** - server settings editing through interface

## System Requirements

- **Operating System**: Debian/Ubuntu (or compatible)
- **Docker**: will be installed automatically by the installer
- **RAM**: minimum 8GB (16GB+ recommended)
- **Storage**: minimum 50GB free space
- **Network**: stable internet connection

## Installation

### Quick Installation (Recommended)

1. Clone the repository:
```bash
git clone https://github.com/kurzejapatryk/icarus-server-manager.git
cd icarus-server-manager
```

2. Run the installer as root:
```bash
sudo ./install.sh
```

The installer will perform the following actions:
- Install Docker and Docker Compose
- Create system user `icarus`
- Copy files to `/opt/icarus-server`
- Configure systemd service
- Create symbolic link `icarus-manager`

### Manual Installation

If you don't want to use the installer:

1. Install Docker and Docker Compose
2. Copy files to chosen directory (e.g., `/opt/icarus-server`)
3. Configure `.env` file with server settings
4. Run `docker compose up -d`

## Configuration

### .env File

After installation, edit the configuration file:

```bash
sudo nano /opt/icarus-server/.env
```

Available settings:

```env
SERVERNAME=YourServerName
JOIN_PASSWORD=playerpassword
ADMIN_PASSWORD=adminpassword
```

**Important**: Change passwords before starting the server!

### Ports

The server uses the following ports (make sure they are open in firewall):

- `17777/udp` - main game port
- `27015/udp` - Steam query port

## Usage

### Management Interface

After installation, use the command:

```bash
icarus-manager
```

Or directly:

```bash
/opt/icarus-server/icarus-manager.sh
```

Available options:
- **START server** - start the server
- **STOP server** - stop the server
- **RESTART server** - restart the server
- **STATUS** - check server status
- **VIEW SERVER LOGS** - display container logs
- **BACKUP world** - create world backup
- **RESTORE backup** - restore backup
- **EDIT SETTINGS** - edit server configuration
- **LANGUAGE** - change interface language

### Systemd Service Control

```bash
# Start server
sudo systemctl start icarus

# Stop server
sudo systemctl stop icarus

# Restart server
sudo systemctl restart icarus

# Check status
sudo systemctl status icarus

# Enable autostart
sudo systemctl enable icarus

# Disable autostart
sudo systemctl disable icarus
```

### Docker Compose

You can also use standard Docker Compose commands:

```bash
cd /opt/icarus-server

# Start server
docker compose up -d

# Stop server
docker compose down

# Display logs
docker compose logs -f icarus

# Update image
docker compose pull
```

#### Volumes Configuration

The `docker-compose.yml` file includes the following volume mapping:

```yaml
volumes:
  - /home/icarus:/home/steam/.wine/drive_c/icarus
```

This mapping provides easy access to upload your own local game saves from the host system level. The `/home/icarus` directory on the host is mapped to the game's save directory inside the container, allowing you to manage save files directly from the host.

## Backups

World backups are stored in the `/home/icarus-backups` directory.

### Automatic Backups

Use cron for automatic backups:

```bash
# Edit crontab
sudo crontab -e

# Add line for daily backup at 2:00 AM
0 2 * * * /opt/icarus-server/icarus-manager.sh backup
```

### Manual Backups

Use the management interface or:

```bash
/opt/icarus-server/icarus-manager.sh backup
```

## Updates

To update the server:

```bash
cd /opt/icarus-server
sudo ./update.sh
```

The script will:
- Pull the latest Docker image
- Stop the server
- Restart with the new version

## Uninstallation

To completely remove the server:

```bash
sudo ./uninstall.sh
```

The script will remove:
- Systemd service
- Installation files
- System user
- Backups (optional)

## Troubleshooting

### Server Won't Start

1. Check logs:
```bash
docker compose logs icarus
```

2. Make sure ports are not occupied:
```bash
sudo netstat -tulpn | grep :17777
```

3. Check service status:
```bash
sudo systemctl status icarus
```

### Memory Issues

If server crashes due to insufficient memory:

1. Increase memory limit for container in `docker-compose.yml`:
```yaml
services:
  icarus:
    deploy:
      resources:
        limits:
          memory: 16G
```

2. Ensure system has enough RAM

### Permission Issues

If you have permission problems:

```bash
# Change file ownership
sudo chown -R icarus:icarus /opt/icarus-server

# Change backup ownership
sudo chown -R icarus:icarus /home/icarus-backups
```

## Support

- **Issues**: [GitHub Issues](https://github.com/kurzejapatryk/icarus-server-manager/issues)
- **Wiki**: [GitHub Wiki](https://github.com/kurzejapatryk/icarus-server-manager/wiki)

## License

MIT License - see [LICENSE](LICENSE) file

## Acknowledgments

- [nerodon/icarus-dedicated](https://hub.docker.com/r/nerodon/icarus-dedicated) - Docker image for Icarus server
- Icarus community for support and information
