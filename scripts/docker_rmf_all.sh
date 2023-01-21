#!/usr/bin/env bash

# Sends SIGKILL to all running containers

running_ids=$(docker ps -q)
IFS="," read -r -a running_ids_array <<<"$running_ids"
docker rm -f "${running_ids_array[@]}"
