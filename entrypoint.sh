#!/usr/bin/env bash
set -e

SUBDIRS=("ssh_keys" "terraform")

for dir in "${SUBDIRS[@]}"; do
	mkdir -p "${USER_DATA_PATH}/${dir}"
done

chown -R "${USERNAME}:${USERNAME}" \
	"${USER_DATA_PATH}" \
	"/home/${USERNAME}/.ssh" \
	"${TF_PLUGIN_CACHE_PATH}" \
	"${ANSIBLE_COLLECTIONS_PATH}" \
	"${PYTHON_VENV_PATH}" \
	"${ROOT_PATH}"

find "${USER_DATA_PATH}/ssh_keys" -type f -exec chmod 600 {} +

exec "$@"
