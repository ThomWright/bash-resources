#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

usage() {
  cat <<EOF
[BRIEF_DESCRIPTION]

Examples:

Run the template:
  ./template.sh

Dependencies:

- [XXX]

Required:

  -a --flag-with-arg       ARG     - A flag with an argument

Optional:

  -o --boolean-flag                - A boolean flag
  -h --help                        - Print this help and exit
EOF
}

log() {
  echo -e "${1:-}" >&2
}
logT() {
  echo -e "$(date -u +'%Y-%m-%dT%H:%M:%SZ') $1" >&2
}

function cleanup {
  logT "Cleaning up"
}
trap cleanup EXIT ERR

parse_params() {
  # TODO: There might be something better we can do here.
  positional_params=""

  while [[ $# -gt 0 ]]; do
    local key="$1"

    case $key in
    -a | --flag-with-arg)
      if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
        my_flag_arg="$2"
        shift
      else
        log "Argument for $1 is missing"
        exit 1
      fi
      ;;
    -o | --boolean-flag)
      boolean_flag=true
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

  # Check required arguments
  local req_args="my_flag_arg" # space-separated list
  for arg in $req_args; do
    if [ -z "${!arg+x}" ]; then
      log "🙈 Missing required parameter: $arg"
      exit 1
    fi
  done

  # Set defaults for optional arguments
  boolean_flag=${boolean_flag:-false}
}

# Check any required dependencies exist
check_environment() {
  local req_commands="jq" # space-separated list
  for comm in $req_commands; do
    if ! command -v $comm &>/dev/null; then
      log "🙈 Required command '$comm' could not be found"
      exit 1
    fi
  done
}

run() {
  logT "Run script..."
  log "my_flag_arg: $my_flag_arg"
  log "boolean_flag: $boolean_flag"
  log "positional arguments: $positional_params"
}

parse_params "$@"
check_environment
run
