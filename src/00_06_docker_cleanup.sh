#!/usr/bin/env bash
set -euo pipefail

# Lista contenedores, imágenes, volúmenes y redes; detiene y elimina todo lo activo de forma segura.

echo "==> Docker info breve"
docker ps -a || true
echo

echo "==> Deteniendo contenedores en ejecución"
RUNNING_IDS=$(docker ps -q)
if [ -n "${RUNNING_IDS}" ]; then
  docker stop ${RUNNING_IDS}
else
  echo "No hay contenedores en ejecución"
fi

echo
echo "==> Eliminando contenedores detenidos"
ALL_IDS=$(docker ps -aq)
if [ -n "${ALL_IDS}" ]; then
  docker rm -f ${ALL_IDS}
else
  echo "No hay contenedores para eliminar"
fi

echo
echo "==> Eliminando redes creadas por usuario (excepto bridge, host, none)"
USR_NETS=$(docker network ls --format '{{.Name}}' | grep -Ev '^(bridge|host|none)$' || true)
if [ -n "${USR_NETS}" ]; then
  # shellcheck disable=SC2086
  docker network rm ${USR_NETS} || true
else
  echo "No hay redes de usuario para eliminar"
fi

echo
echo "==> Eliminando volúmenes huérfanos"
ORPHAN_VOLS=$(docker volume ls -qf dangling=true)
if [ -n "${ORPHAN_VOLS}" ]; then
  docker volume rm ${ORPHAN_VOLS}
else
  echo "No hay volúmenes huérfanos"
fi

echo
echo "==> Limpieza general de Docker (imágenes/volúmenes/caché sin uso)"
docker system prune -af --volumes || true

echo
echo "==> Estado final"
echo "Contenedores:"
docker ps -a || true
echo "Imágenes:"
docker images || true
echo "Volúmenes:"
docker volume ls || true
echo "Redes:"
docker network ls || true

echo "\nHecho."


