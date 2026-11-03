#!/usr/bin/env bash
# Arregla apt en Debian 11 (bullseye) cuando los repositorios oficiales
# devuelven 404 porque la versión ya pasó a archive.debian.org.
#
# Uso:
#   ./scripts/arreglar_apt_bullseye.sh
#
# Es idempotente: si las fuentes ya apuntan al archivo, no rompe nada.
set -euo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

log()  { printf '\033[0;32m[OK]\033[0m %s\n' "$*"; }
info() { printf '\033[0;34m[..]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!!]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

if [ "${VERSION_CODENAME:-}" != "bullseye" ]; then
    warn "Este arreglo es solo para Debian 11 (bullseye)."
    warn "Sistema detectado: ${PRETTY_NAME:-desconocido}"
    exit 0
fi

command -v apt-get >/dev/null 2>&1 || fail "No encuentro apt-get."

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/apt/sources.list.bak.${STAMP}"

info "Respaldando /etc/apt/sources.list en ${BACKUP}"
$SUDO cp -a /etc/apt/sources.list "${BACKUP}"

info "Redirigiendo deb.debian.org y security.debian.org a archive.debian.org"
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
    [ -f "${f}" ] || continue
    $SUDO sed -i \
        -e 's|https*://deb.debian.org/debian|http://archive.debian.org/debian|g' \
        -e 's|https*://security.debian.org/debian-security|http://archive.debian.org/debian-security|g' \
        -e 's|https*://ftp.debian.org/debian|http://archive.debian.org/debian|g' \
        "${f}"
done

# Los Releases del archivo ya no tienen Valid-Until vigente.
echo 'Acquire::Check-Valid-Until "false";' \
    | $SUDO tee /etc/apt/apt.conf.d/99archive >/dev/null
log "Configurado /etc/apt/apt.conf.d/99archive"

info "Actualizando índices de apt..."
if ! $SUDO apt-get update; then
    warn "apt-get update falló. Revisa las fuentes con:"
    warn "    cat /etc/apt/sources.list"
    warn "    cat /etc/apt/sources.list.d/*.list"
    exit 1
fi

log "apt listo. Ahora puedes ejecutar ./scripts/preparar_pi.sh"
