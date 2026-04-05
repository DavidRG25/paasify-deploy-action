#!/usr/bin/env bash
set -euo pipefail

CODE_PATH="${INPUT_CODE_PATH:-.}"
ZIP_OUTPUT="/tmp/paasify_code.zip"

echo "📦 Comprimiendo código desde '${CODE_PATH}' → ${ZIP_OUTPUT}"

if [[ ! -d "${CODE_PATH}" ]]; then
  echo "❌ Error: El directorio '${CODE_PATH}' no existe"
  exit 1
fi

# Eliminar zip previo si existe
rm -f "${ZIP_OUTPUT}"

# Comprimir excluyendo directorios/archivos innecesarios
cd "${CODE_PATH}"
zip -r "${ZIP_OUTPUT}" . \
  --exclude "*.git*" \
  --exclude "*/node_modules/*" \
  --exclude "*/__pycache__/*" \
  --exclude "*/.venv/*" \
  --exclude "*/venv/*" \
  --exclude ".env"

ZIP_SIZE=$(du -sh "${ZIP_OUTPUT}" | cut -f1)
echo "✅ Zip creado: ${ZIP_OUTPUT} (${ZIP_SIZE})"
