#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="${PACK_DIR:-/opt/minecraft}"
DATA_DIR="${DATA_DIR:-/data}"

log() {
  printf '%s %s\n' "[minecraft-entrypoint]" "$*" >&2
}

log "starting (PACK_DIR=${PACK_DIR} DATA_DIR=${DATA_DIR})"

mkdir -p "${DATA_DIR}"

sync_pack_file() {
  local rel_path="$1"
  local src="${PACK_DIR}/${rel_path}"
  local dst="${DATA_DIR}/${rel_path}"

  if [[ -f "${src}" ]]; then
    mkdir -p "$(dirname "${dst}")"
    log "copying ${src} to ${dst}"
    cp -f "${src}" "${dst}"
  else
    log "skipping ${src}; source file not found"
  fi
}

if [[ -z "$(find "${DATA_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  log "data dir empty; copying pack from ${PACK_DIR} to ${DATA_DIR}"
  cp -a "${PACK_DIR}/." "${DATA_DIR}/"
else
  log "data dir has content; skipping pack copy"
fi

sync_pack_file "config/ftbchunks-world.snbt"
sync_pack_file "server.properties"
sync_pack_file "server-startup-config.yaml"

if [[ -f /etc/minecraft/server.properties ]]; then
  log "copying mounted server.properties to ${DATA_DIR}/server.properties"
  cp -f /etc/minecraft/server.properties "${DATA_DIR}/server.properties"
fi

if [[ -f /etc/minecraft/server-startup-config.yaml ]]; then
  log "copying mounted server-startup-config.yaml to ${DATA_DIR}/server-startup-config.yaml"
  cp -f /etc/minecraft/server-startup-config.yaml "${DATA_DIR}/server-startup-config.yaml"
fi

log "starting server (cwd ${DATA_DIR})"
cd "${DATA_DIR}"
exec ./startserver.sh
