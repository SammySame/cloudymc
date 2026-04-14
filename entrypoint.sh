#!/usr/bin/env bash
set -e

SUBDIRS=("ssh_keys" "terraform")

for dir in "${SUBDIRS[@]}"; do
	mkdir -p "${USER_DATA_PATH}/${dir}"
done

find "${USER_DATA_PATH}/ssh_keys" -type f -exec chmod 600 {} +

exec "$@"
