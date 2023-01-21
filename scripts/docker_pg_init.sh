#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

# TODO: use flags instead of env vars?
POSTGRES_DOCKER_VERSION="${POSTGRES_DOCKER_VERSION:=13.6-alpine}"
POSTGRES_HOST="${POSTGRES_HOST:=localhost}"
POSTGRES_PORT="${POSTGRES_PORT:=5432}"
POSTGRES_ROOT_USER="${POSTGRES_ROOT_USER:=postgres}"
POSTGRES_ROOT_PASSWORD="${POSTGRES_ROOT_PASSWORD:=password}"
POSTGRES_ROOT_DB="${POSTGRES_ROOT_DB:=postgres}"
POSTGRES_APP_DB="${POSTGRES_APP_DB:=my-postgres}"
POSTGRES_CONTAINER_NAME="${POSTGRES_CONTAINER_NAME:=${POSTGRES_APP_DB}-db}"

usage() {
  cat <<EOF
Initialise a PostgreSQL database in Docker.

Dependencies:

- docker
- psql

Optional:
      --replace             - Replace any existing container with the same name.
  -h  --help                - Print this help and exit.
EOF
}

log() {
  echo -e "${1:-}" >&2
}
logT() {
  echo -e "$(date -u +'%Y-%m-%dT%H:%M:%SZ') $1" >&2
}

parse_params() {
  # Set defaults for optional arguments
  replace_container=false

  while [[ $# -gt 0 ]]; do
    local key="$1"

    case $key in
    --replace)
      replace_container=true
      ;;
    -h | --help)
      usage
      exit
      ;;
    --* | -*)
      log "❌ Error: Unsupported flag: $1"
      exit 1
      ;;
    *) # preserve positional params
      positional_params="$positional_params $1"
      ;;
    esac
    shift
  done
}

# Check any required dependencies exist
check_environment() {
  local req_commands="docker psql" # space-separated list
  for comm in $req_commands; do
    if ! command -v "$comm" &>/dev/null; then
      log "🙈 Required command '$comm' could not be found"
      exit 1
    fi
  done
}

run() {
  log "cd into script directory"
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
  cd "${SCRIPT_DIR}"

  if [ "$replace_container" = "true" ]; then
    log "Remove existing container (if exists)"
    docker rm -f "${POSTGRES_CONTAINER_NAME}" || true
  fi

  log "Start container"
  docker start "${POSTGRES_CONTAINER_NAME}" 2>/dev/null || docker run \
    -e POSTGRES_USER="${POSTGRES_ROOT_USER}" \
    -e POSTGRES_PASSWORD="${POSTGRES_ROOT_PASSWORD}" \
    -e POSTGRES_PORT="${POSTGRES_PORT}" \
    -e POSTGRES_DB="${POSTGRES_ROOT_DB}" \
    -p "${POSTGRES_PORT}":5432 \
    --rm \
    --name "${POSTGRES_CONTAINER_NAME}" \
    -d postgres:"${POSTGRES_DOCKER_VERSION}" \
    postgres -N 1000 # -N max_connections

  local psql_args=( -h localhost -U "${POSTGRES_ROOT_USER}" -p "${POSTGRES_PORT}" -d "${POSTGRES_ROOT_DB}" )

  log "Wait until Postgres is available..."
  until PGPASSWORD=${POSTGRES_ROOT_PASSWORD} psql "${psql_args[@]}" -c '\q' 2>/dev/null; do
    log "Postgres at postgres://${POSTGRES_ROOT_USER}@localhost:${POSTGRES_PORT}/${POSTGRES_ROOT_DB} is unavailable. Retrying in 1 second."
    sleep 1
  done
  log "Postgres at postgres://${POSTGRES_ROOT_USER}@localhost:${POSTGRES_PORT}/${POSTGRES_ROOT_DB} is available."

  local database_exists
  database_exists=$(PGPASSWORD=${POSTGRES_ROOT_PASSWORD} psql "${psql_args[@]}" --tuples-only --command="SELECT 1 FROM pg_database WHERE datname = '${POSTGRES_APP_DB}'")

  if [[ "$database_exists" == *1* ]]; then
    log "Database '$POSTGRES_APP_DB' already exists"
  else
    log "Create app database"
    PGPASSWORD=${POSTGRES_ROOT_PASSWORD} psql "${psql_args[@]}" -c --quiet \
      --command="CREATE DATABASE \"${POSTGRES_APP_DB}\";"
  fi

  log "Postgres is ready to go!"
}

parse_params "$@"
check_environment
run
