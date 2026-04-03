#!/usr/bin/env bash
set -e

SUBDIRS=("ssh_keys" "terraform")

for dir in "${SUBDIRS[@]}"; do
	mkdir -p "${USER_DATA_PATH}/${dir}"
done

exec "$@"
