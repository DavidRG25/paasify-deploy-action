# PaaSify Deploy Action

![GitHub release](https://img.shields.io/github/v/release/DavidRG25/paasify-deploy-action)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

GitHub Action oficial para desplegar aplicaciones en **PaaSify** directamente desde tu repositorio. Crea el servicio si no existe, o lo actualiza si ya estaba desplegado.

---

## Quick Start (modo dockerhub)

```yaml
- name: Deploy to PaaSify
  uses: DavidRG25/paasify-deploy-action@v1
  with:
    mode: dockerhub
    paasify_api_url: ${{ secrets.PAASIFY_API_URL }}
    paasify_token: ${{ secrets.PAASIFY_TOKEN }}
    name: mi-app
    image: usuario/mi-app:latest
    internal_port: 8000
    project_id: ${{ secrets.PROJECT_ID }}
    subject_id: ${{ secrets.SUBJECT_ID }}
```

---

## Modos soportados

| Modo | Descripción | Cuándo usarlo |
|---|---|---|
| `dockerhub` | Despliega desde una imagen pública de DockerHub | Imagen ya construida y subida a DockerHub |
| `custom_dockerfile` | Sube tu código + Dockerfile y PaaSify construye la imagen | Proyectos privados con Dockerfile propio |
| `custom_compose` | Sube tu código + docker-compose.yml | Proyectos multi-contenedor |

> ⚠️ En modo `dockerhub`, la imagen debe ser **pública**. Para proyectos privados usa `custom_dockerfile` o `custom_compose`.

---

## Ejemplos completos

### Ejemplo 1: `dockerhub`

Flujo completo con build, push a DockerHub y deploy en PaaSify.

```yaml
name: CI/CD con DockerHub

on:
  push:
    branches: [main]

env:
  SERVICE_NAME: mi-app
  INTERNAL_PORT: 8000

jobs:
  build-and-push:
    name: Build & Push
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login a DockerHub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build & Push imagen
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.SERVICE_NAME }}:latest

  deploy:
    name: Deploy a PaaSify
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to PaaSify
        uses: DavidRG25/paasify-deploy-action@v1
        with:
          mode: dockerhub
          paasify_api_url: ${{ secrets.PAASIFY_API_URL }}
          paasify_token: ${{ secrets.PAASIFY_TOKEN }}
          name: ${{ env.SERVICE_NAME }}
          image: ${{ secrets.DOCKERHUB_USERNAME }}/${{ env.SERVICE_NAME }}:latest
          internal_port: ${{ env.INTERNAL_PORT }}
          project_id: ${{ secrets.PROJECT_ID }}
          subject_id: ${{ secrets.SUBJECT_ID }}
```

---

### Ejemplo 2: `custom_dockerfile`

PaaSify construye la imagen a partir de tu Dockerfile. No necesitas DockerHub.

```yaml
name: Deploy Custom Dockerfile

on:
  push:
    branches: [main]

env:
  SERVICE_NAME: mi-app-custom

jobs:
  deploy:
    name: Deploy a PaaSify
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Deploy to PaaSify
        uses: DavidRG25/paasify-deploy-action@v1
        with:
          mode: custom_dockerfile
          paasify_api_url: ${{ secrets.PAASIFY_API_URL }}
          paasify_token: ${{ secrets.PAASIFY_TOKEN }}
          name: ${{ env.SERVICE_NAME }}
          code_path: .
          dockerfile_path: ./Dockerfile
          project_id: ${{ secrets.PROJECT_ID }}
          subject_id: ${{ secrets.SUBJECT_ID }}
```

---

### Ejemplo 3: `custom_compose`

Para proyectos multi-contenedor. PaaSify autodetecta los puertos del compose.

```yaml
name: Deploy Custom Compose

on:
  push:
    branches: [main]

env:
  SERVICE_NAME: mi-app-compose

jobs:
  deploy:
    name: Deploy a PaaSify
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Deploy to PaaSify
        uses: DavidRG25/paasify-deploy-action@v1
        with:
          mode: custom_compose
          paasify_api_url: ${{ secrets.PAASIFY_API_URL }}
          paasify_token: ${{ secrets.PAASIFY_TOKEN }}
          name: ${{ env.SERVICE_NAME }}
          code_path: .
          docker_compose_path: ./docker-compose.yml
          project_id: ${{ secrets.PROJECT_ID }}
          subject_id: ${{ secrets.SUBJECT_ID }}
```

---

## Inputs

### Inputs comunes (todos los modos)

| Input | Obligatorio | Default | Descripción |
|---|---|---|---|
| `mode` | ✅ | — | `dockerhub`, `custom_dockerfile` o `custom_compose` |
| `paasify_api_url` | ✅ | — | URL base de la API (ej: `http://host:8000/api`) |
| `paasify_token` | ✅ | — | Token de autenticación del alumno |
| `name` | ✅ | — | Nombre del servicio en PaaSify |
| `project_id` | ✅ | — | ID del proyecto en PaaSify |
| `subject_id` | ✅ | — | ID de la asignatura en PaaSify |
| `container_type` | ⭕ | `web` | `web`, `api`, `database`, `misc` |
| `is_web` | ⭕ | `true` | ¿Es accesible por web? |
| `keep_volumes` | ⭕ | `true` | ¿Conservar datos entre reinicios? |

### Inputs específicos

| Input | Solo en modo | Obligatorio | Descripción |
|---|---|---|---|
| `image` | `dockerhub` | ✅ | Imagen pública (ej: `usuario/app:v1`) |
| `internal_port` | `dockerhub` | ✅ | Puerto interno de escucha |
| `env_vars` | `dockerhub` | ⭕ | Variables de entorno como JSON string. Default: `{}` |
| `code_path` | `custom_*` | ⭕ | Directorio a comprimir. Default: `.` |
| `dockerfile_path` | `custom_dockerfile` | ✅ | Ruta al Dockerfile |
| `docker_compose_path` | `custom_compose` | ✅ | Ruta al docker-compose.yml |

---

## Outputs

| Output | Descripción |
|---|---|
| `container_id` | ID del servicio creado o actualizado en PaaSify |
| `action_taken` | `created` o `patched` |

Ejemplo de uso de outputs:

```yaml
- name: Deploy to PaaSify
  id: deploy
  uses: DavidRG25/paasify-deploy-action@v1
  with:
    # ...

- name: Mostrar resultado
  run: |
    echo "ID del servicio: ${{ steps.deploy.outputs.container_id }}"
    echo "Acción: ${{ steps.deploy.outputs.action_taken }}"
```

---

## Secrets necesarios

| Secret | Requerido en | Descripción |
|---|---|---|
| `PAASIFY_API_URL` | Todos | URL de la API de PaaSify |
| `PAASIFY_TOKEN` | Todos | Token de autenticación |
| `PROJECT_ID` | Todos | ID del proyecto |
| `SUBJECT_ID` | Todos | ID de la asignatura |
| `DOCKERHUB_USERNAME` | Solo `dockerhub` | Usuario de DockerHub |
| `DOCKERHUB_TOKEN` | Solo `dockerhub` | Token de DockerHub |

---

## Errores comunes

**`❌ Error: 'image' es obligatorio en modo dockerhub`**
→ Asegúrate de incluir el input `image` cuando uses `mode: dockerhub`.

**`❌ Dockerfile no encontrado en './Dockerfile'`**
→ El workflow necesita un paso `actions/checkout@v4` antes de usar esta Action.

**`❌ Error al consultar la API (HTTP 401)`**
→ El `paasify_token` es incorrecto o ha expirado. Verifica el secret en tu repo.

**`❌ Error en la petición POST (HTTP 400)`**
→ Algún campo obligatorio es incorrecto. Revisa `project_id` y `subject_id`.

**La imagen no se actualiza en PaaSify**
→ Asegúrate de usar un tag de versión (ej: `:v1.2`) en lugar de `:latest`. PaaSify necesita detectar un cambio.

---

## Licencia

MIT — ver [LICENSE](LICENSE)
