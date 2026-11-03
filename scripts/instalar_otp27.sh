#!/usr/bin/env bash
# Instala Erlang/OTP 27 compilado desde fuente en una Raspberry Pi
# (física o virtual en AVH/Corellium), para que emu_flavor sea "jit".
#
# Uso:
#   chmod +x scripts/instalar_otp27.sh
#   ./scripts/instalar_otp27.sh
#
# Para ejecutarlo sin la pregunta de confirmación:
#   OTP27_YES=1 ./scripts/instalar_otp27.sh
#
# Variables opcionales:
#   OTP_VERSION=27.3.4.19   versión a compilar
#   JOBS=4                  trabajos paralelos de make (por defecto nproc)
#   PREFIX=$HOME/otp/27.3.4.19
#
# ADVERTENCIA: compilar OTP tarda entre 30 y 90 minutos en una Pi de 4 núcleos.
# El trial de AVH da 100 core-hours; 4 núcleos encendidos consumen 4 por hora.
set -euo pipefail

OTP_VERSION="${OTP_VERSION:-27.3.4.19}"
PREFIX="${PREFIX:-$HOME/otp/${OTP_VERSION}}"
JOBS="${JOBS:-$(nproc)}"
BUILD_DIR="${BUILD_DIR:-$HOME/otp-build}"
TARBALL="${BUILD_DIR}/otp_src_${OTP_VERSION}.tar.gz"
SRC_DIR="${BUILD_DIR}/otp_src_${OTP_VERSION}"
REBAR3_VERSION="${REBAR3_VERSION:-3.21.0}"
REBAR3_URL="https://github.com/erlang/rebar3/releases/download/${REBAR3_VERSION}/rebar3"
BIN_DIR="${HOME}/.local/bin"

log()  { printf '\033[0;32m[OK]\033[0m %s\n' "$*"; }
info() { printf '\033[0;34m[..]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!!]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname -m)" = "aarch64" ] || warn "No estás en aarch64; el script funciona igual, pero no es una Pi."
command -v sudo >/dev/null 2>&1 || fail "Se necesita sudo para instalar dependencias."

if [ "${OTP27_YES:-0}" != "1" ]; then
    echo "Se va a compilar Erlang/OTP ${OTP_VERSION} en ${PREFIX}."
    echo "Esto puede tardar entre 30 y 90 minutos y consume horas del trial de AVH."
    read -r -p "¿Continuar? [s/N] " respuesta
    case "${respuesta}" in
        s|S|si|SI|sí|SÍ) ;;
        *) echo "Cancelado."; exit 0 ;;
    esac
fi

echo "============================================================"
echo " 1. Dependencias de compilación"
echo "============================================================"
info "Actualizando apt..."
sudo apt-get update -qq
# No instalamos wxWidgets: compilamos con --without-wx porque AVH es headless.
info "Instalando build-essential, OpenSSL, ncurses, SSH y ODBC..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    build-essential \
    libssl-dev \
    libncurses-dev \
    libssh-dev \
    unixodbc-dev \
    git \
    curl \
    ca-certificates \
    tar
log "Dependencias instaladas."
echo

echo "============================================================"
echo " 2. Descargando el código fuente de OTP ${OTP_VERSION}"
echo "============================================================"
mkdir -p "${BUILD_DIR}"
if [ ! -f "${TARBALL}" ]; then
    info "Descargando otp_src_${OTP_VERSION}.tar.gz (~100 MB)..."
    curl -fL --retry 3 \
        "https://github.com/erlang/otp/releases/download/OTP-${OTP_VERSION}/otp_src_${OTP_VERSION}.tar.gz" \
        -o "${TARBALL}" || fail "No se pudo descargar OTP. Revisa la conexión."
else
    log "El tarball ya existe; se reutiliza."
fi
rm -rf "${SRC_DIR}"
mkdir -p "${SRC_DIR}"
info "Extrayendo..."
tar -xzf "${TARBALL}" -C "${SRC_DIR}" --strip-components=1
log "Código fuente listo en ${SRC_DIR}."
echo

echo "============================================================"
echo " 3. Compilando OTP ${OTP_VERSION} (JIT nativo aarch64)"
echo "============================================================"
cd "${SRC_DIR}"

# Primero intentamos con JIT. Si el compilador de Debian 11 (gcc 10) no puede
# con el JIT de OTP 27, reintentamos sin JIT para que al menos tengas OTP 27.
build_otp() {
    ./configure --prefix="${PREFIX}" \
        --enable-kernel-poll \
        --enable-jit \
        --without-javac \
        --without-wx || return 1
    make -j"${JOBS}" || return 1
    make install || return 1
}

if ! build_otp; then
    warn "Falló la compilación con JIT. Reintentando sin JIT..."
    warn "Si esto también falla, revisa el error de configure/make de arriba."
    make distclean >/dev/null 2>&1 || true
    ./configure --prefix="${PREFIX}" \
        --enable-kernel-poll \
        --disable-jit \
        --without-javac \
        --without-wx
    make -j"${JOBS}"
    make install
fi

log "OTP ${OTP_VERSION} instalado en ${PREFIX}."
echo

echo "============================================================"
echo " 4. Activando OTP ${OTP_VERSION} en el PATH"
echo "============================================================"
export PATH="${PREFIX}/bin:${PATH}"
if ! grep -qF "${PREFIX}/bin" "${HOME}/.bashrc" 2>/dev/null; then
    {
        echo ""
        echo "# Erlang/OTP ${OTP_VERSION} compilado para la práctica"
        echo "export PATH=\"${PREFIX}/bin:\$PATH\""
    } >> "${HOME}/.bashrc"
fi
log "Se agregó ${PREFIX}/bin al PATH de ~/.bashrc."
echo

echo "============================================================"
echo " 5. Instalando rebar3"
echo "============================================================"
REBAR3_OK=0
if command -v rebar3 >/dev/null 2>&1 && rebar3 version >/dev/null 2>&1; then
    log "rebar3 ya está instalado: $(rebar3 version)"
    REBAR3_OK=1
fi
if [ "${REBAR3_OK}" -eq 0 ]; then
    mkdir -p "${BIN_DIR}"
    info "Descargando rebar3 ${REBAR3_VERSION}..."
    curl -fsSL "${REBAR3_URL}" -o "${BIN_DIR}/rebar3" || fail "No se pudo descargar rebar3."
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
echo " 6. Verificación"
echo "============================================================"
ERL_VSN="$(erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().')"
FLAVOR="$(erl -noshell -eval 'io:format("~p", [erlang:system_info(emu_flavor)]), halt().')"
ARCH_INFO="$(erl -noshell -eval 'io:format("~s", [erlang:system_info(system_architecture)]), halt().')"
echo "OTP Release : ${ERL_VSN}"
echo "JIT flavor  : ${FLAVOR}"
echo "Arch        : ${ARCH_INFO}"
echo "rebar3      : $(rebar3 version)"
if [ "${ERL_VSN}" != "27" ]; then
    warn "Se esperaba OTP 27 y se obtuvo ${ERL_VSN}. Revisa el PATH."
fi
if [ "${FLAVOR}" != "jit" ]; then
    warn "emu_flavor = ${FLAVOR} (no es 'jit')."
    warn "El proyecto funciona igual, pero si el profesor exige JIT tendrás que"
    warn "usar una imagen más nueva (Debian 12/13) o un CM5 físico."
fi
echo
echo "Para usar OTP 27 en esta terminal:"
echo "    source ~/.bashrc"
echo "    cd ~/practica_erlang_otp && ./scripts/preparar_pi.sh"
echo
echo "RECUERDA apagar la instancia de AVH al terminar."
