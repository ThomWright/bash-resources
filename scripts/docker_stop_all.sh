#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

# Sends SIGTERM to all running containers

running_ids=$(docker ps -q)
readarray -t running_ids_array <<<"$running_ids"

docker stop ${running_ids_array[@]+"${running_ids_array[@]}"}
