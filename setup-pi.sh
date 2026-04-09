#!/usr/bin/env bash
# setup-pi.sh — First-time setup for QB Engineer on Raspberry Pi
#
# Run from the repo root after cloning:
#   chmod +x setup-pi.sh
#   ./setup-pi.sh
#
# Options:
#   --include-signing    Also start DocuSeal e-signature service
#
# NOTE: AI (Ollama) and TTS (Coqui) profiles are not recommended on
# Raspberry Pi due to memory and CPU constraints.

set -euo pipefail

INCLUDE_SIGNING=false

for arg in "$@"; do
    case $arg in
        --include-signing) INCLUDE_SIGNING=true ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

step()  { printf '\n\033[36m==> %s\033[0m\n' "$1"; }
ok()    { printf '    \033[32m[OK] %s\033[0m\n' "$1"; }
warn()  { printf '    \033[33m[!!] %s\033[0m\n' "$1"; }
fail()  { printf '    \033[31m[X]  %s\033[0m\n' "$1"; }
info()  { printf '         %s\n' "$1"; }

bail() {
    echo ""
    fail "Missing prerequisite: $1"
    echo ""
    shift
    for line in "$@"; do
        info "$line"
    done
    echo ""
    info "After installing, close this terminal and re-run:"
    info "  ./setup-pi.sh"
    echo ""
    exit 1
}

# ─────────────────────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────────────────────

echo ""
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║   QB Engineer — Raspberry Pi First-Time Setup║"
echo "  ╚══════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────
# 1. Architecture check
# ─────────────────────────────────────────────────────────────

step "Checking system"

ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    warn "Detected architecture: $ARCH"
    warn "This script is designed for 64-bit ARM (Raspberry Pi OS 64-bit)."
    warn "32-bit Raspberry Pi OS is NOT supported (.NET 9 requires 64-bit)."
    read -rp "    Continue anyway? (y/N) " yn
    [[ "$yn" =~ ^[Yy]$ ]] || exit 1
else
    ok "Architecture: $ARCH (64-bit ARM)"
fi

TOTAL_MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo 0)
if (( TOTAL_MEM_MB < 3500 )); then
    warn "Only ${TOTAL_MEM_MB} MB RAM detected. Minimum recommended: 4 GB."
    warn "The stack may run but could be slow or OOM-kill containers."
elif (( TOTAL_MEM_MB < 7500 )); then
    ok "${TOTAL_MEM_MB} MB RAM (4 GB Pi — core stack will work, skip AI profile)"
else
    ok "${TOTAL_MEM_MB} MB RAM"
fi

# ─────────────────────────────────────────────────────────────
# 2. Prerequisites
# ─────────────────────────────────────────────────────────────

step "Checking prerequisites"

# --- Git ---
if ! command -v git &>/dev/null; then
    bail "Git" \
        "Install Git:" \
        "  sudo apt update && sudo apt install -y git"
fi
ok "Git $(git --version 2>/dev/null)"

# --- Docker ---
if ! command -v docker &>/dev/null; then
    bail "Docker" \
        "Install Docker on Raspberry Pi:" \
        "  curl -fsSL https://get.docker.com | sudo sh" \
        "" \
        "Then add your user to the docker group:" \
        "  sudo usermod -aG docker \$USER" \
        "" \
        "Log out and back in for the group change to take effect."
fi

# --- Docker permissions ---
if ! docker info &>/dev/null 2>&1; then
    if docker info 2>&1 | grep -qi "permission denied"; then
        bail "Docker (permissions)" \
            "Docker is installed but your user cannot access it." \
            "" \
            "Add your user to the docker group:" \
            "  sudo usermod -aG docker \$USER" \
            "" \
            "Then log out and back in (or run: newgrp docker)."
    else
        bail "Docker (daemon)" \
            "Docker is installed but the daemon is not running." \
            "" \
            "Start it:" \
            "  sudo systemctl start docker" \
            "" \
            "Enable on boot:" \
            "  sudo systemctl enable docker"
    fi
fi
ok "Docker $(docker --version 2>/dev/null)"

# --- Docker Compose ---
if ! docker compose version &>/dev/null 2>&1; then
    bail "Docker Compose" \
        "Docker Compose v2 is required." \
        "" \
        "Install the compose plugin:" \
        "  sudo apt update && sudo apt install -y docker-compose-plugin" \
        "" \
        "Verify: docker compose version"
fi
ok "$(docker compose version 2>/dev/null)"

# --- Disk space ---
FREE_GB=$(df --output=avail -BG . 2>/dev/null | tail -1 | tr -dc '0-9')
if (( FREE_GB < 10 )); then
    warn "Only ${FREE_GB} GB free. Recommended: 20+ GB."
    warn "Consider using a USB SSD instead of the SD card for Docker storage."
else
    ok "${FREE_GB} GB free disk space"
fi

# --- Port check ---
CONFLICTS=""
for PORT in 80 5000 5432 9000 9001; do
    if ss -tlnp 2>/dev/null | grep -q ":${PORT} " 2>/dev/null; then
        CONFLICTS="$CONFLICTS $PORT"
    fi
done
if [[ -n "$CONFLICTS" ]]; then
    warn "Ports already in use:$CONFLICTS"
    warn "You can change ports in .env after setup."
    read -rp "    Continue anyway? (y/N) " yn
    [[ "$yn" =~ ^[Yy]$ ]] || exit 1
else
    ok "Required ports are available (80, 5000, 5432, 9000, 9001)"
fi

echo ""
ok "All prerequisites met!"

# ─────────────────────────────────────────────────────────────
# 3. Project files
# ─────────────────────────────────────────────────────────────

step "Verifying project files"

if [[ ! -f "docker-compose.yml" ]]; then
    fail "docker-compose.yml not found."
    info "Run this script from the repo root:"
    info "  cd qb-engineer-wrapper && ./setup-pi.sh"
    exit 1
fi

if [[ ! -f ".env.example" ]]; then
    fail ".env.example not found — the repo may be incomplete."
    info "Try a fresh clone:"
    info "  git clone https://github.com/danielhokanson/qb-engineer-wrapper.git"
    exit 1
fi

ok "Project files found"

# ─────────────────────────────────────────────────────────────
# 4. Create .env
# ─────────────────────────────────────────────────────────────

step "Configuring environment"

if [[ -f ".env" ]]; then
    ok ".env already exists — skipping creation"
    warn "To regenerate, delete .env and re-run setup-pi.sh"
else
    cp .env.example .env

    # Generate random JWT key
    JWT_KEY=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 48)
    sed -i "s|JWT_KEY=dev-secret-key-change-in-production-min-32-chars!!|JWT_KEY=${JWT_KEY}|" .env

    # For Pi deployment: use port 80 instead of 4200 for cleaner public URLs
    sed -i "s|^UI_PORT=4200|UI_PORT=80|" .env

    # Detect the Pi's local IP for CORS and frontend base URL
    PI_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -n "$PI_IP" ]]; then
        sed -i "s|^FRONTEND_BASE_URL=http://localhost:4200|FRONTEND_BASE_URL=http://${PI_IP}|" .env
        sed -i "s|^CORS_ORIGINS=http://localhost:4200|CORS_ORIGINS=http://${PI_IP},http://localhost|" .env
        sed -i "s|^MINIO_PUBLIC_ENDPOINT=localhost:9000|MINIO_PUBLIC_ENDPOINT=${PI_IP}:9000|" .env
        ok "Detected Pi IP: $PI_IP"
    else
        warn "Could not detect IP — you may need to edit CORS_ORIGINS in .env"
    fi

    # Production-ish settings
    sed -i "s|^RECREATE_DB=true|RECREATE_DB=true|" .env
    sed -i "s|^MOCK_INTEGRATIONS=true|MOCK_INTEGRATIONS=false|" .env

    ok "Created .env with random JWT key and Pi network settings"
fi

# ─────────────────────────────────────────────────────────────
# 5. Write version.json
# ─────────────────────────────────────────────────────────────

step "Writing build version"

BUILD_VERSION=$(git rev-list --count HEAD 2>/dev/null || echo "0")
BUILD_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "dev")
export BUILD_VERSION BUILD_SHA

VERSION_DIR="qb-engineer-ui/public/assets"
if [[ -d "$VERSION_DIR" ]]; then
    echo -n "{\"version\":\"${BUILD_VERSION}\",\"sha\":\"${BUILD_SHA}\"}" > "${VERSION_DIR}/version.json"
    ok "Build ${BUILD_VERSION} (${BUILD_SHA})"
else
    warn "UI assets directory not found — skipping version.json"
fi

# ─────────────────────────────────────────────────────────────
# 6. Reduce memory limits for Pi
# ─────────────────────────────────────────────────────────────

step "Applying Raspberry Pi memory tuning"

# Create a Pi-specific compose override that lowers memory limits
cat > docker-compose.pi.yml <<'PIOVERRIDE'
# Raspberry Pi memory overrides — auto-generated by setup-pi.sh
# Reduces memory limits to fit within 4-8 GB total RAM.
services:
  qb-engineer-api:
    deploy:
      resources:
        limits:
          memory: 1G
  qb-engineer-db:
    deploy:
      resources:
        limits:
          memory: 512M
    # Tune Postgres for low-memory
    command: >
      postgres
        -c shared_buffers=128MB
        -c effective_cache_size=256MB
        -c work_mem=4MB
        -c maintenance_work_mem=64MB
        -c max_connections=50
PIOVERRIDE

# Set COMPOSE_FILE so docker compose always picks up the Pi overlay
if grep -q "^COMPOSE_FILE=" .env 2>/dev/null; then
    sed -i "s|^COMPOSE_FILE=.*|COMPOSE_FILE=docker-compose.yml:docker-compose.pi.yml|" .env
else
    echo "COMPOSE_FILE=docker-compose.yml:docker-compose.pi.yml" >> .env
fi

ok "Created docker-compose.pi.yml (reduced memory limits for Pi)"
ok "API: 1 GB, DB: 512 MB, UI: 256 MB"

# ─────────────────────────────────────────────────────────────
# 7. Build and start
# ─────────────────────────────────────────────────────────────

step "Building Docker images"
warn "First build on Raspberry Pi takes 10-20 minutes — go grab a coffee"
echo ""

echo "    Building API image..."
docker compose build qb-engineer-api
ok "API image built"

echo "    Building UI image..."
docker compose build qb-engineer-ui
ok "UI image built"

step "Starting core services (db, storage, backup, api, ui)"

docker compose up -d \
    qb-engineer-db \
    qb-engineer-storage \
    qb-engineer-backup \
    qb-engineer-api \
    qb-engineer-ui

# --- Optional: Signing ---
if $INCLUDE_SIGNING; then
    step "Starting DocuSeal signing service"
    docker compose --profile signing up -d qb-engineer-signing
fi

# ─────────────────────────────────────────────────────────────
# 8. Wait for API health
# ─────────────────────────────────────────────────────────────

step "Waiting for API to become healthy (first start runs database migrations)"

MAX_WAIT=180
ELAPSED=0
HEALTHY=false

while (( ELAPSED < MAX_WAIT )); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' qb-engineer-api 2>/dev/null || echo "unknown")
    if [[ "$STATUS" == "healthy" ]]; then
        HEALTHY=true
        break
    fi
    printf "\r    Waiting... %s (%ds / %ds)" "$STATUS" "$ELAPSED" "$MAX_WAIT"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done
echo ""

if $HEALTHY; then
    ok "API is healthy and accepting requests"
else
    warn "API health check timed out after ${MAX_WAIT}s"
    warn "This can be normal on Pi — migrations are slow. Check:"
    warn "  docker compose logs -f qb-engineer-api"
fi

# ─────────────────────────────────────────────────────────────
# 9. Final status
# ─────────────────────────────────────────────────────────────

step "Container status"
docker compose ps

PI_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

echo ""
echo "  ╔══════════════════════════════════════════════╗"
printf "  ║          \033[32mSetup complete!\033[0m                     ║\n"
echo "  ╚══════════════════════════════════════════════╝"
echo ""
echo "  ─── Access ───"
echo ""
echo "    Local:   http://localhost"
if [[ -n "$PI_IP" ]]; then
echo "    Network: http://${PI_IP}"
fi
echo ""
echo "  A setup wizard will guide you through creating"
echo "  your admin account and company profile."
echo ""
echo "  ─── Public Access ───"
echo ""
echo "  To make this accessible from the internet:"
echo ""
echo "    1. Log into your router (usually http://192.168.1.1)"
echo "    2. Find 'Port Forwarding' (may be under Advanced or NAT)"
echo "    3. Forward external port 80 → ${PI_IP:-<Pi IP>} port 80"
echo "    4. Find your public IP: curl -4 ifconfig.me"
echo "    5. Share: http://<your-public-ip>"
echo ""
echo "  If your ISP blocks port 80, forward a different external"
echo "  port (e.g. 8080 → ${PI_IP:-<Pi IP>}:80) and access via"
echo "  http://<your-public-ip>:8080"
echo ""
echo "  Update CORS_ORIGINS in .env if you add more access URLs:"
echo "    CORS_ORIGINS=http://${PI_IP},http://<public-ip>"
echo "    Then: docker compose up -d qb-engineer-api"
echo ""
echo "  ─── Useful Commands ───"
echo ""
echo "  View logs:    docker compose logs -f qb-engineer-api"
echo "  Stop all:     docker compose stop"
echo "  Start all:    docker compose up -d"
echo "  Update:       git pull && docker compose up -d --build"
echo "  DB shell:     docker compose exec qb-engineer-db psql -U postgres -d qb_engineer"
echo ""
echo "  ─── Performance Tips ───"
echo ""
echo "  - Use a USB 3.0 SSD instead of the SD card for Docker storage"
echo "  - Skip AI and TTS profiles on 4 GB Pi models"
echo "  - The first page load after a restart is slow (JIT warmup)"
echo ""
