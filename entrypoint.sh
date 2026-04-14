#!/usr/bin/env bash
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Safety check for rootless Podman users
# UserNS=keep-id:uid=1000,gid=1000 should be used for mapping UID and GID
if [ "$(id -u)" = '0' ] && [ -w /etc/passwd ]; then
	usermod -o -u "${PUID}" "${USERNAME}"
	groupmod -o -g "${PGID}" "${USERNAME}"
fi

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

exec gosu "$USERNAME" "$@"
