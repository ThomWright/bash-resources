#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

usage() {
  cat <<EOF
Push a stack of branches.

USAGE:

  git_push_stack [OPTIONS] BRANCH_PATTERN

ARGS:

  <BRANCH_PATTERN>
    A pattern matching a set of branches, using grep syntax.

OPTIONS:

  -f, --force
    Forces the git push.

EXAMPLES:

  Push all branches for \`my-feature\`:

    git_push_stack my-feature

DEPENDENCIES:

  - grep
  - git
EOF
}

log() {
  echo -e "${1:-}" >&2
}

parse_params() {
  # Set defaults for optional arguments
  force=${force:-false}

  while [[ $# -gt 0 ]]; do
    local key="$1"

    case $key in
    -f | --force)
      force=true
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
      if [ -z "${branch_pattern+x}" ]; then
        branch_pattern="$1"
      else
        log "🙈 More than one branch pattern set"
        exit 1
      fi
      ;;
    esac
    shift
  done

  # Check required arguments
  local req_args="branch_pattern" # space-separated list
  for arg in $req_args; do
    if [ -z "${!arg+x}" ]; then
      log "🙈 Missing required parameter: $arg"
      exit 1
    fi
  done
}

parse_params "$@"

git for-each-ref --format='%(refname:short)' refs/heads/ \
  | grep "$branch_pattern" \
  | xargs git push --atomic --set-upstream origin
