#!/usr/bin/env bash
# Empaqueta el proyecto sin _build ni archivos temporales, para subirlo a AVH.
#
# Uso, desde la raíz del proyecto:
#   ./scripts/empaquetar_avh.sh [ruta-del-tar.gz]
#
# Ejemplo:
#   ./scripts/empaquetar_avh.sh ~/practica_erlang_otp_avh.tar.gz
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_NAME="$(basename "${PROJECT_ROOT}")"
OUT="${1:-$HOME/${PROJECT_NAME}_avh.tar.gz}"

cd "$(dirname "${PROJECT_ROOT}")"
tar \
    --exclude="${PROJECT_NAME}/_build" \
    --exclude="${PROJECT_NAME}/.git" \
    --exclude="${PROJECT_NAME}/.gitignore" \
    --exclude="*.beam" \
    --exclude="*.dat" \
    -czf "${OUT}" \
    "${PROJECT_NAME}"

echo "[OK] Paquete creado: ${OUT}"
ls -lh "${OUT}"
echo
echo "Súbelo a la Pi virtual con el visor de archivos de AVH o con scp:"
echo "  scp -J <proyecto>@proxy.app.avh.arm.com ${OUT} pi@10.11.0.1:~/"
echo "Luego, en la consola de la Pi:"
echo "  tar -xzf ~/$(basename "${OUT}")"
echo "  cd ~/${PROJECT_NAME}"
