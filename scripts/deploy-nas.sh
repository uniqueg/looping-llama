#!/usr/bin/env bash
set -eo pipefail

NAS_HOST="${NAS_HOST:-synology.local}"
NAS_USER="${NAS_USER:-admin}"
TARGET_PATH="/volume1/docker"

echo "Syncing container manifests to ${NAS_USER}@${NAS_HOST}:${TARGET_PATH}..."

ssh "${NAS_USER}@${NAS_HOST}" "mkdir -p ${TARGET_PATH}/ntfy/cache ${TARGET_PATH}/ntfy/data ${TARGET_PATH}/openbao/config ${TARGET_PATH}/openbao/data"

scp templates/synology/ntfy/server.yml "${NAS_USER}@${NAS_HOST}:${TARGET_PATH}/ntfy/server.yml"
scp templates/synology/ntfy/docker-compose.yml "${NAS_USER}@${NAS_HOST}:${TARGET_PATH}/ntfy/docker-compose.yml"
scp templates/synology/openbao/bao.hcl "${NAS_USER}@${NAS_HOST}:${TARGET_PATH}/openbao/config/bao.hcl"
scp templates/synology/openbao/docker-compose.yml "${NAS_USER}@${NAS_HOST}:${TARGET_PATH}/openbao/docker-compose.yml"

echo "[OK] Deployment manifests synchronized. Start stacks via Container Manager or:"
echo "     ssh ${NAS_USER}@${NAS_HOST} 'docker compose -f ${TARGET_PATH}/openbao/docker-compose.yml up -d'"
