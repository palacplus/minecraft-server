#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="${PACK_DIR:-/opt/minecraft}"
DATA_DIR="${DATA_DIR:-/data}"

log() {
  printf '%s %s\n' "[minecraft-entrypoint]" "$*" >&2
}

log "starting (PACK_DIR=${PACK_DIR} DATA_DIR=${DATA_DIR})"

mkdir -p "${DATA_DIR}"

if [[ -z "$(find "${DATA_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  log "data dir empty; copying pack from ${PACK_DIR} to ${DATA_DIR}"
  cp -a "${PACK_DIR}/." "${DATA_DIR}/"
else
  log "data dir has content; skipping pack copy"
fi

if [[ -f /etc/minecraft/server.properties ]]; then
  log "copying mounted server.properties to ${DATA_DIR}/server.properties"
  cp /etc/minecraft/server.properties "${DATA_DIR}/server.properties"
fi

log "starting server (cwd ${DATA_DIR})"
cd "${DATA_DIR}"
exec ./startserver.sh
