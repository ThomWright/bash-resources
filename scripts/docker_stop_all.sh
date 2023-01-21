#!/usr/bin/env bash

# Sends SIGTERM to all running containers

running_ids=$(docker ps -q)
IFS="," read -r -a running_ids_array <<<"$running_ids"
docker stop "${running_ids_array[@]}"
