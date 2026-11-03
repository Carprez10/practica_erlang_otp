#!/usr/bin/env bash
# Prepara una Raspberry Pi (física o virtual en AVH/Corellium) para la práctica.
#
# Uso, desde la raíz del proyecto:
#   chmod +x scripts/preparar_pi.sh
#   ./scripts/preparar_pi.sh
#
# Esta es la RUTA RÁPIDA: instala el Erlang que trae Debian (OTP 23 en
# bullseye, 25 en bookworm, 27 en trixie) y un rebar3 compatible.
# El proyecto compila y pasa las 165 pruebas en OTP 23 o superior.
#
# Si necesitas OTP 27 con JIT (como pide el gist del profesor), ejecuta
# primero:  ./scripts/instalar_otp27.sh
# y después este script otra vez.
set -euo pipefail

REBAR3_VERSION="${REBAR3_VERSION:-3.21.0}"
REBAR3_URL="https://github.com/erlang/rebar3/releases/download/${REBAR3_VERSION}/rebar3"
BIN_DIR="${HOME}/.local/bin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

log()  { printf '\033[0;32m[OK]\033[0m %s\n' "$*"; }
info() { printf '\033[0;34m[..]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!!]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[ -f rebar.config ] || fail "No encuentro rebar.config. Ejecuta este script desde la raíz de practica_erlang_otp/."
command -v sudo >/dev/null 2>&1 || fail "Se necesita sudo para instalar Erlang."

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

echo "============================================================"
echo " 1. Sistema operativo y arquitectura"
echo "============================================================"
uname -a
echo "Distribución: ${PRETTY_NAME:-desconocida}"
echo "Arquitectura: $(uname -m)"
echo "Núcleos: $(nproc)"
free -h || true
echo

ARCH="$(uname -m)"
case "${ARCH}" in
    aarch64|arm64) log "Arquitectura ARM64 correcta." ;;
    *) warn "No es aarch64 (${ARCH}). Compilará igual, pero no es una Raspberry Pi." ;;
esac

echo "============================================================"
echo " 2. Instalando Erlang y herramientas del sistema"
echo "============================================================"

# Debian 11 (bullseye) terminó su soporte en agosto de 2026 y sus
# paquetes se movieron a archive.debian.org. La imagen de AVH conserva
# listas viejas y apt devuelve 404. Este arreglo es idempotente.
if [ "${VERSION_CODENAME:-}" = "bullseye" ] && \
   ! grep -qs 'archive.debian.org' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    warn "Debian 11 está en archive.debian.org; ajustando repositorios..."
    "${SCRIPT_DIR}/arreglar_apt_bullseye.sh"
fi

info "Actualizando apt..."
sudo apt-get update -qq

# erlang-nox = Erlang sin GUI (suficiente para esta práctica y para AVH).
# En Debian 11 (bullseye) instala OTP 23; en Debian 13 (trixie), OTP 27.
info "Instalando erlang-nox, git, curl..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    erlang-nox \
    git \
    ca-certificates \
    curl
log "Erlang instalado desde apt."
echo

echo "============================================================"
echo " 3. Instalando rebar3"
echo "============================================================"
# OJO: en Debian 11 NO existe el paquete apt "rebar3". Por eso se
# descarga el escript oficial y se instala en ~/.local/bin.
REBAR3_OK=0
if command -v rebar3 >/dev/null 2>&1; then
    if rebar3 version >/dev/null 2>&1; then
        log "rebar3 ya está instalado: $(rebar3 version)"
        REBAR3_OK=1
    else
        warn "Hay un rebar3 que no funciona; se reinstalará."
    fi
fi

if [ "${REBAR3_OK}" -eq 0 ]; then
    mkdir -p "${BIN_DIR}"
    info "Descargando rebar3 ${REBAR3_VERSION}..."
    if ! curl -fsSL "${REBAR3_URL}" -o "${BIN_DIR}/rebar3"; then
        fail "No se pudo descargar rebar3. Revisa la conexión a Internet de la Pi."
    fi
    chmod +x "${BIN_DIR}/rebar3"
    export PATH="${BIN_DIR}:${PATH}"
    if ! grep -q '\.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
    fi
    log "rebar3 instalado en ${BIN_DIR}/rebar3"
fi
export PATH="${BIN_DIR}:${PATH}"
rebar3 version
echo

echo "============================================================"
echo " 4. Versiones instaladas"
echo "============================================================"
ERL_VSN="$(erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().')"
FLAVOR="$(erl -noshell -eval 'io:format("~p", [erlang:system_info(emu_flavor)]), halt().')"
ERTS_VSN="$(erl -noshell -eval 'io:format("~s", [erlang:system_info(version)]), halt().')"
echo "Erlang/OTP: ${ERL_VSN} (ERTS ${ERTS_VSN})"
echo "emu_flavor: ${FLAVOR}"
echo "rebar3: $(rebar3 version)"
if [ "${ERL_VSN}" -lt 27 ] 2>/dev/null; then
    warn "El gist del profesor pide OTP 27 con JIT."
    warn "Esta ruta instala OTP ${ERL_VSN} (el que trae Debian). El proyecto es compatible,"
    warn "pero emu_flavor NO será 'jit'. Si el profesor exige JIT, ejecuta:"
    warn "    ./scripts/instalar_otp27.sh"
fi
echo

echo "============================================================"
echo " 5. Compilación"
echo "============================================================"
rebar3 compile
echo

echo "============================================================"
echo " 6. Pruebas EUnit"
echo "============================================================"
rebar3 eunit

echo
echo "============================================================"
log "Listo: si ves '165 tests, 0 failures', la práctica funciona en esta Pi."
echo "============================================================"
echo "Para la demostración:   ./scripts/demo_pi.sh"
echo "Para empaquetar:         ./scripts/empaquetar_avh.sh"
echo
echo "RECUERDA: al terminar, apaga la instancia de AVH desde el panel"
echo "(botón de encendido) para no consumir las horas del trial."
