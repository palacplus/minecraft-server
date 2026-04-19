#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="${PACK_DIR:-/opt/minecraft}"
DATA_DIR="${DATA_DIR:-/data}"

# Everything under the pack in the image overwrites matching names in /data on each start, except world/ and logs/
# (case-insensitive) when /data already has content — so restarts keep the volume. If /data is empty (fresh volume),
# the full pack is copied including world/ and logs/. Requires bash 4+ for ${var,,}. Basenames with / are skipped
# so rm never targets odd paths. Runtime-only paths that exist only on the volume (not in the image) are left alone.
# Helm may still override user_jvm_args.txt after this block when /etc/minecraft/user_jvm_args.txt is mounted.
sync_pack_from_image() {
  : "${DATA_DIR:?DATA_DIR must be set}"
  : "${PACK_DIR:?PACK_DIR must be set}"
  mkdir -p "${DATA_DIR}"
  local data_empty=0
  if [[ -z "$(find "${DATA_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    data_empty=1
  fi
  local item base base_lc
  while IFS= read -r -d '' item; do
    base="${item##*/}"
    base_lc="${base,,}"
    # Preserve world/logs on the volume after first sync; seed them only when /data was empty.
    if [[ "$data_empty" -eq 0 ]]; then
      case "$base_lc" in
        world|logs) continue ;;
      esac
    fi
    # No slashes or empty names: avoids odd find results touching paths outside /data.
    [[ -n "$base" && "$base" != "." && "$base" != ".." && "$base" != */* ]] || continue
    rm -rf "${DATA_DIR}/${base}"
    cp -a "${item}" "${DATA_DIR}/"
    if [[ -f "${DATA_DIR}/${base}" && "${base}" == *.sh ]]; then
      chmod +x "${DATA_DIR}/${base}"
    fi
  done < <(find "${PACK_DIR}" -mindepth 1 -maxdepth 1 -print0)
}
sync_pack_from_image

if [[ -f /etc/minecraft/user_jvm_args.txt ]]; then
  cp /etc/minecraft/user_jvm_args.txt "${DATA_DIR}/user_jvm_args.txt"
fi

# Chart server.properties mounted at /etc/minecraft (Helm ConfigMap or compose).
if [[ -f /etc/minecraft/server.properties ]]; then
  cp /etc/minecraft/server.properties "${DATA_DIR}/server.properties"
fi

cd "${DATA_DIR}"
exec ./run.sh
