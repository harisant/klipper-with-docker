# 🖨️ Klipper with Docker

Comprehensive documentation and architecture guide for the **Klipper 3D Printing Ecosystem** based on **Docker Compose**. This setup integrates **Klipper** (Firmware Engine), **Moonraker** (API Middleware), and **Mainsail** (Web User Interface) into a modular, isolated, and portable containerized stack.

---

## 📋 Table of Contents
1. [Overview & Architecture](#-overview--architecture)
2. [File Verification & Cross-Check](#-file-verification--cross-check)
3. [Detailed Component & File Breakdown](#-detailed-component--file-breakdown)
4. [Installation & Quick Start Guide](#-installation--quick-start-guide)
5. [Adding a New Printer Profile](#-adding-a-new-printer-profile)
6. [Compiling MCU Firmware](#-compiling-mcu-firmware)
7. [Troubleshooting](#-troubleshooting)

---

## 🏗️ Overview & Architecture

This ecosystem uses a 3-layer microservice pattern (Client -> API Middleware -> Core Daemon -> Hardware):

```
┌─────────────────────────────────────────────────────────────┐
│                      Mainsail Web UI                        │
│             (Web Interface via Nginx Port :8000)            │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTP API / WebSocket
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        Moonraker                            │
│                 (API Middleware Port :7125)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ Unix Domain Socket (/opt/printer_data/run/klippy.sock)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                         Klipper                             │
│                  (Klippy Python Daemon)                     │
└──────────────────────────────┬──────────────────────────────┘
                               │ Serial/USB Connection (/dev/serial/by-id/...)
                               ▼
                     Hardware MCU / 3D Printer
```

---

## 🔍 File Verification & Cross-Check

All files have been cross-checked and verified for consistent integration:

| File | Verification Status | Description & Integration |
| :--- | :---: | :--- |
| `docker-compose.yml` | ✅ Verified | Services `klipper`, `moonraker`, `mainsail`, and `klipper-builder` are fully configured. Ports and environment variables map cleanly to `.env`. |
| `.env.example` & `.env` | ✅ Verified | Holds dynamic variables: `PRINTER_TYPE`, `MCU_SERIAL`, `TZ`, `MAINSAIL_PORT`, `MOONRAKER_PORT`, and printer kinematic constraints. |
| `.gitignore` | ✅ Verified | Properly ignores `.env` and the entire runtime directory `klipper/printer_data/`. |
| `klipper/Dockerfile` | ✅ Verified | Multi-stage build using Debian Bookworm Slim, compiling Python venv for Klipper `v0.13.0`. |
| `klipper/Dockerfile.builder` | ✅ Verified | Includes cross-compilation toolchains (`gcc-avr`, `avrdude`, `arm-none-eabi`) for building MCU firmware. |
| `klipper/entrypoint.sh` | ✅ Verified | Automated startup script to create `/opt/printer_data` subdirectories, select `PRINTER_TYPE` profile, and parse environment variables into `printer.cfg`. |
| `klipper/printer_configs/` | ✅ Verified | Contains template profile files `ender3_pro.cfg`, `generic_cartesian.cfg`, and `voron24.cfg`. |
| `moonraker/Dockerfile` | ✅ Verified | Multi-stage build based on Python 3.11 Slim Bookworm, compiling Moonraker `v0.11.0` venv. |
| `moonraker/moonraker.conf` | ✅ Verified | Defines server endpoint (`0.0.0.0:7125`), Klipper UDS socket path, CORS headers, and trusted IP ranges. |
| `mainsail/nginx.conf` | ✅ Verified | Nginx reverse-proxy configuration targeting Moonraker on port `7125` for `/api/` and `/websocket`. |

---

## 📁 Detailed Component & File Breakdown

### 1. Environment & Git Configuration

#### `docker-compose.yml`
- **`klipper`**:
  - `privileged: true` & volume `- /dev:/dev`: Provides full access to host physical serial/USB devices.
  - `- ./klipper/printer_configs:/opt/printer_configs:ro`: Mounted read-only to supply printer profile templates.
  - `- ./klipper/printer_data:/opt/printer_data`: Mounted to store generated runtime configuration, logs, and gcodes.
- **`moonraker`**:
  - `ports: - "${MOONRAKER_PORT:-7125}:7125"`: Exposes the Moonraker API port.
  - `- ./moonraker/moonraker.conf:/opt/printer_data/config/moonraker.conf:ro`: Mounts the base Moonraker configuration.
- **`mainsail`**:
  - Image: `ghcr.io/mainsail-crew/mainsail:latest`.
  - `ports: - "${MAINSAIL_PORT:-8000}:8080"`: Exposes the Mainsail Web UI port.

#### `.env` & `.env.example`
Centralized environment variables for per-machine and per-printer configurations:
```env
TZ=Asia/Jakarta
PRINTER_TYPE=ender3_pro
MCU_SERIAL=/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0
MAINSAIL_PORT=8000
MOONRAKER_PORT=7125
PRINTER_KINEMATICS=cartesian
PRINTER_MAX_VELOCITY=300
PRINTER_MAX_ACCEL=3000
PRINTER_MAX_Z_VELOCITY=5
PRINTER_MAX_Z_ACCEL=100
```

#### `.gitignore`
Ignores sensitive files (`.env`), OS junk (`.DS_Store`), and runtime data generated dynamically at container startup (`klipper/printer_data/`).

---

### 2. Klipper Service

#### `klipper/Dockerfile`
- Multi-stage build using `debian:bookworm-slim`.
- `builder` stage: Clones official Klipper repository (`v0.13.0`) and installs Python requirements into `/opt/klipper-env`.
- `runtime` stage: Copies built artifacts and executes `entrypoint.sh`.

#### `klipper/entrypoint.sh`
Container startup script:
1. Executes `mkdir -p` to guarantee `/opt/printer_data/{config,gcodes,logs,run}` exist inside the container.
2. Reads `PRINTER_TYPE` from environment variables.
3. Loads the profile template from `/opt/printer_configs/${PRINTER_TYPE}.cfg`.
4. Uses Python `string.Template` to perform safe substitution of variables (such as `${MCU_SERIAL}`) into `/opt/printer_data/config/printer.cfg`.
5. Spawns the `klippy.py` Python daemon.

#### `klipper/printer_configs/`
Holds reusable printer profile templates:
- **`ender3_pro.cfg`**: Pinout and config template for Creality Ender 3 Pro (Board 4.2.2 / STM32F103).
- **`generic_cartesian.cfg`**: Standard template for generic Cartesian printers.
- **`voron24.cfg`**: Standard template for CoreXY printers (Voron 2.4).

---

### 3. Moonraker & Mainsail Services

#### `moonraker/moonraker.conf`
Configures Moonraker API endpoints:
- Listens on `0.0.0.0:7125`.
- Klipper Unix Domain Socket: `/opt/printer_data/run/klippy.sock`.
- Authorized local IPs (`192.168.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12`) and wildcard CORS (`*`).

#### `mainsail/nginx.conf`
Configures Nginx reverse proxy for Mainsail Web UI:
- `/`: Serves the Mainsail Single Page Application (SPA).
- `/websocket`: Proxies WebSockets to `http://moonraker:7125/websocket`.
- `/api/`: Proxies HTTP REST API calls to `http://moonraker:7125`.

---

## 🚀 Installation & Quick Start Guide

### 1. Prerequisites
Ensure Docker and Docker Compose are installed on your host system. Clone this repository and prepare `.env`:

```bash
git clone <repository_url>
cd klipper-with-docker
cp .env.example .env
```

### 2. Locate Your Printer MCU Serial Path
Connect your 3D printer via USB to the host computer, then locate its serial ID:

```bash
ls /dev/serial/by-id/*
```
*Example output:* `/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0`

### 3. Update Environment Variables in `.env`
Edit `.env` to reflect your serial path and printer model:

```env
PRINTER_TYPE=ender3_pro
MCU_SERIAL=/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0
MAINSAIL_PORT=8000
```

### 4. Launch the Stack
Build and start all services in detached mode:

```bash
docker compose up -d
```

Access the Mainsail Web Dashboard in your browser:
👉 **`http://localhost:8000`** (or `http://<HOST_IP>:8000`)

---

## ➕ Adding a New Printer Profile

To add support for a new printer model (e.g., `prusa_mk3s`):

1. Create a new template file at `klipper/printer_configs/prusa_mk3s.cfg`.
2. Add your Klipper configuration parameters.
3. Replace the serial path in the `[mcu]` section with:
   ```ini
   [mcu]
   serial: ${MCU_SERIAL}
   ```
4. Set `PRINTER_TYPE=prusa_mk3s` in `.env`.
5. Restart the Klipper container:
   ```bash
   docker compose restart klipper
   ```

---

## 🛠️ Compiling MCU Firmware

If you need to compile Klipper `.bin` firmware for your printer mainboard:

1. Launch Klipper's interactive `menuconfig`:
   ```bash
   docker compose run --rm klipper-builder make menuconfig
   ```
2. Select your micro-controller architecture, bootloader offset, and communication interface.
3. Run the compilation build:
   ```bash
   docker compose run --rm klipper-builder make
   ```
4. The generated firmware binary (`klipper.bin`) will be output in the build directory.

---

## ❓ Troubleshooting

### 1. Mainsail shows "Disconnected from Moonraker"
- Verify Moonraker is running: `docker compose ps`.
- Check Moonraker logs: `docker compose logs -f moonraker`.

### 2. Klipper reports "Unable to connect to MCU"
- Ensure USB connection is secure.
- Verify `MCU_SERIAL` in `.env` matches the output of `ls /dev/serial/by-id/*`.
- Ensure `privileged: true` is set under `klipper` service in `docker-compose.yml`.

### 3. View Real-Time Klipper Logs
```bash
docker compose logs -f klipper
```
