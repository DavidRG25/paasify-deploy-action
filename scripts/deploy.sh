#!/usr/bin/env bash
set -euo pipefail

API_URL="${INPUT_PAASIFY_API_URL%/}"  # quitar trailing slash si existe
TOKEN="${INPUT_PAASIFY_TOKEN}"
MODE="${INPUT_MODE}"
NAME="${INPUT_NAME}"
PROJECT_ID="${INPUT_PROJECT_ID}"
SUBJECT_ID="${INPUT_SUBJECT_ID}"
CONTAINER_TYPE="${INPUT_CONTAINER_TYPE:-web}"
IS_WEB="${INPUT_IS_WEB:-true}"
KEEP_VOLUMES="${INPUT_KEEP_VOLUMES:-true}"

echo ""
echo "════════════════════════════════════════"
echo "  🚀 PaaSify Deploy Action"
echo "════════════════════════════════════════"
echo "  Servicio : ${NAME}"
echo "  Modo     : ${MODE}"
echo "  Proyecto : ${PROJECT_ID}"
echo "════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────
# PASO 1: GET — buscar si el servicio ya existe
# ─────────────────────────────────────────
echo "🔍 Buscando servicio '${NAME}' en proyecto ${PROJECT_ID}..."

GET_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer ${TOKEN}" \
  "${API_URL}/containers/?project=${PROJECT_ID}")

HTTP_BODY=$(echo "${GET_RESPONSE}" | head -n -1)
HTTP_CODE=$(echo "${GET_RESPONSE}" | tail -n 1)

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "❌ Error al consultar la API (HTTP ${HTTP_CODE}):"
  echo "${HTTP_BODY}"
  exit 1
fi

CONTAINER_ID=$(echo "${HTTP_BODY}" | jq -r --arg NAME "${NAME}" \
  'if type == "array" then . else .results end | map(select(.name == $NAME)) | first | .id // empty')

# ─────────────────────────────────────────
# PASO 2: Decidir método (POST o PATCH)
# ─────────────────────────────────────────
if [[ -n "${CONTAINER_ID}" ]]; then
  METHOD="PATCH"
  ENDPOINT="${API_URL}/containers/${CONTAINER_ID}/"
  ACTION_TAKEN="patched"
  echo "📝 Servicio encontrado (ID: ${CONTAINER_ID}) → actualizando (PATCH)"
else
  METHOD="POST"
  ENDPOINT="${API_URL}/containers/"
  ACTION_TAKEN="created"
  echo "🆕 Servicio no encontrado → creando (POST)"
fi

# ─────────────────────────────────────────
# PASO 3: Ejecutar petición según modo
# ─────────────────────────────────────────
case "${MODE}" in

  dockerhub)
    IMAGE="${INPUT_IMAGE}"
    INTERNAL_PORT="${INPUT_INTERNAL_PORT}"
    ENV_VARS="${INPUT_ENV_VARS:-{\}}"

    echo "🐳 Modo dockerhub — imagen: ${IMAGE}, puerto: ${INTERNAL_PORT}"

    if [[ "${METHOD}" == "POST" ]]; then
      PAYLOAD=$(jq -n \
        --arg name "${NAME}" \
        --arg mode "${MODE}" \
        --arg image "${IMAGE}" \
        --argjson port "${INTERNAL_PORT}" \
        --arg type "${CONTAINER_TYPE}" \
        --argjson is_web "${IS_WEB}" \
        --argjson keep_volumes "${KEEP_VOLUMES}" \
        --argjson project "${PROJECT_ID}" \
        --argjson subject "${SUBJECT_ID}" \
        --argjson env_vars "${ENV_VARS}" \
        '{
          name: $name,
          mode: $mode,
          image: $image,
          internal_port: $port,
          container_type: $type,
          is_web: $is_web,
          keep_volumes: $keep_volumes,
          project: $project,
          subject: $subject,
          env_vars: $env_vars
        }')
    else
      PAYLOAD=$(jq -n \
        --arg image "${IMAGE}" \
        --argjson port "${INTERNAL_PORT}" \
        --argjson env_vars "${ENV_VARS}" \
        '{image: $image, internal_port: $port, env_vars: $env_vars}')
    fi

    RESPONSE=$(curl -s -w "\n%{http_code}" \
      -X "${METHOD}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${PAYLOAD}" \
      "${ENDPOINT}")
    ;;

  custom_dockerfile)
    DOCKERFILE_PATH="${INPUT_DOCKERFILE_PATH}"
    ZIP_PATH="/tmp/paasify_code.zip"

    echo "🐳 Modo custom_dockerfile — dockerfile: ${DOCKERFILE_PATH}"

    if [[ "${METHOD}" == "POST" ]]; then
      RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X "${METHOD}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "name=${NAME}" \
        -F "mode=custom" \
        -F "container_type=${CONTAINER_TYPE}" \
        -F "is_web=${IS_WEB}" \
        -F "keep_volumes=${KEEP_VOLUMES}" \
        -F "internal_port=${INTERNAL_PORT}" \
        -F "project=${PROJECT_ID}" \
        -F "subject=${SUBJECT_ID}" \
        -F "code=@${ZIP_PATH};type=application/zip" \
        -F "dockerfile=@${DOCKERFILE_PATH}" \
        "${ENDPOINT}")
    else
      RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X "${METHOD}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "internal_port=${INTERNAL_PORT}" \
        -F "code=@${ZIP_PATH};type=application/zip" \
        -F "dockerfile=@${DOCKERFILE_PATH}" \
        "${ENDPOINT}")
    fi
    ;;

  custom_compose)
    COMPOSE_PATH="${INPUT_DOCKER_COMPOSE_PATH}"
    ZIP_PATH="/tmp/paasify_code.zip"

    echo "🐳 Modo custom_compose — compose: ${COMPOSE_PATH}"

    if [[ "${METHOD}" == "POST" ]]; then
      RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X "${METHOD}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "name=${NAME}" \
        -F "mode=custom" \
        -F "container_type=${CONTAINER_TYPE}" \
        -F "is_web=${IS_WEB}" \
        -F "keep_volumes=${KEEP_VOLUMES}" \
        -F "internal_port=${INTERNAL_PORT}" \
        -F "project=${PROJECT_ID}" \
        -F "subject=${SUBJECT_ID}" \
        -F "code=@${ZIP_PATH};type=application/zip" \
        -F "docker_compose=@${COMPOSE_PATH}" \
        "${ENDPOINT}")
    else
      RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X "${METHOD}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -F "internal_port=${INTERNAL_PORT}" \
        -F "code=@${ZIP_PATH};type=application/zip" \
        -F "docker_compose=@${COMPOSE_PATH}" \
        "${ENDPOINT}")
    fi
    ;;

esac

# ─────────────────────────────────────────
# PASO 4: Procesar respuesta
# ─────────────────────────────────────────
HTTP_BODY=$(echo "${RESPONSE}" | head -n -1)
HTTP_CODE=$(echo "${RESPONSE}" | tail -n 1)

if [[ "${HTTP_CODE}" != "200" && "${HTTP_CODE}" != "201" ]]; then
  echo "❌ Error en la petición ${METHOD} (HTTP ${HTTP_CODE}):"
  echo "${HTTP_BODY}"
  exit 1
fi

RETURNED_ID=$(echo "${HTTP_BODY}" | jq -r '.id // empty')

if [[ -z "${RETURNED_ID}" ]]; then
  echo "❌ No se pudo extraer el ID del servicio de la respuesta:"
  echo "${HTTP_BODY}"
  exit 1
fi

# ─────────────────────────────────────────
# PASO 5: Escribir outputs y resumen
# ─────────────────────────────────────────
echo "container_id=${RETURNED_ID}" >> "${GITHUB_OUTPUT}"
echo "action_taken=${ACTION_TAKEN}" >> "${GITHUB_OUTPUT}"

echo ""
echo "════════════════════════════════════════"
echo "  ✅ Despliegue completado"
echo "════════════════════════════════════════"
echo "  ID       : ${RETURNED_ID}"
echo "  Acción   : ${ACTION_TAKEN}"
echo "  Servicio : ${NAME}"
echo "════════════════════════════════════════"
echo ""
