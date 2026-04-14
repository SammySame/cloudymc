#!/usr/bin/env bash
set -e

SUBDIRS=("ssh_keys" "terraform")

for dir in "${SUBDIRS[@]}"; do
	mkdir -p "${USER_DATA_PATH}/${dir}"
done

chmod 600 "${USER_DATA_PATH}/ssh_keys/*"

exec "$@"
