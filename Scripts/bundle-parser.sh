#!/bin/bash
set -euo pipefail

ROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PARSER_DIR="${ROOT}/Vendor/bank-statement-parser"

if [[ "${CONFIGURATION:-Debug}" == "Debug" ]]; then
  echo "Skipping parser bundle in Debug (uses BANKPARSE_ROOT venv)."
  exit 0
fi

PRODUCT="${PRODUCT_NAME:-BankStatementViewer}"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT}.app/Contents/Resources/bin"
DEST_BIN="${DEST_DIR}/bankparse"

if [[ ! -d "${PARSER_DIR}" ]]; then
  echo "error: Vendor/bank-statement-parser missing. Run: git submodule update --init"
  exit 1
fi

ARCH="$(uname -m)"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "${BUILD_DIR}"' EXIT

python3 -m venv "${BUILD_DIR}/venv"
source "${BUILD_DIR}/venv/bin/activate"
pip install -q --upgrade pip
pip install -q pyinstaller
pip install -q "${PARSER_DIR}"

pyinstaller -y --onefile --name bankparse \
  --distpath "${BUILD_DIR}/dist" \
  --workpath "${BUILD_DIR}/build" \
  --specpath "${BUILD_DIR}" \
  --hidden-import pdfplumber \
  --hidden-import PIL \
  --hidden-import PIL._imaging \
  --collect-all pdfplumber \
  --collect-submodules bankparse \
  --paths "${PARSER_DIR}" \
  "${BUILD_DIR}/venv/bin/bankparse"

mkdir -p "${DEST_DIR}"
cp "${BUILD_DIR}/dist/bankparse" "${DEST_BIN}"
chmod +x "${DEST_BIN}"
echo "Bundled parser at ${DEST_BIN} (${ARCH})"
