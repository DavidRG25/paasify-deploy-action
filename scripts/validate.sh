#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Validando inputs para modo: ${INPUT_MODE}"

case "${INPUT_MODE}" in

  dockerhub)
    if [[ -z "${INPUT_IMAGE}" ]]; then
      echo "❌ Error: 'image' es obligatorio en modo dockerhub"
      exit 1
    fi
    if [[ -z "${INPUT_INTERNAL_PORT}" ]]; then
      echo "❌ Error: 'internal_port' es obligatorio en modo dockerhub"
      exit 1
    fi
    echo "✅ Modo dockerhub — image: ${INPUT_IMAGE}, port: ${INPUT_INTERNAL_PORT}"
    ;;

  custom_dockerfile)
    if [[ -z "${INPUT_DOCKERFILE_PATH}" ]]; then
      echo "❌ Error: 'dockerfile_path' es obligatorio en modo custom_dockerfile"
      exit 1
    fi
    if [[ ! -f "${INPUT_DOCKERFILE_PATH}" ]]; then
      echo "❌ Error: Dockerfile no encontrado en '${INPUT_DOCKERFILE_PATH}'"
      exit 1
    fi
    if [[ ! -d "${INPUT_CODE_PATH}" ]]; then
      echo "❌ Error: code_path '${INPUT_CODE_PATH}' no existe o no es un directorio"
      exit 1
    fi
    echo "✅ Modo custom_dockerfile — dockerfile: ${INPUT_DOCKERFILE_PATH}, code: ${INPUT_CODE_PATH}"
    ;;

  custom_compose)
    if [[ -z "${INPUT_DOCKER_COMPOSE_PATH}" ]]; then
      echo "❌ Error: 'docker_compose_path' es obligatorio en modo custom_compose"
      exit 1
    fi
    if [[ ! -f "${INPUT_DOCKER_COMPOSE_PATH}" ]]; then
      echo "❌ Error: docker-compose.yml no encontrado en '${INPUT_DOCKER_COMPOSE_PATH}'"
      exit 1
    fi
    if [[ ! -d "${INPUT_CODE_PATH}" ]]; then
      echo "❌ Error: code_path '${INPUT_CODE_PATH}' no existe o no es un directorio"
      exit 1
    fi
    echo "✅ Modo custom_compose — compose: ${INPUT_DOCKER_COMPOSE_PATH}, code: ${INPUT_CODE_PATH}"
    ;;

  *)
    echo "❌ Error: Modo '${INPUT_MODE}' no válido. Usa: dockerhub, custom_dockerfile o custom_compose"
    exit 1
    ;;

esac

echo "✅ Validación completada"
