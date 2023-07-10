#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

usage() {
  cat <<EOF
Push a stack of branches.

Examples:

Push all branches for \`my-feature\`:
  git_push_stack my-feature

Dependencies:

- grep
- git
EOF
}

log() {
  echo -e "${1:-}" >&2
}

if [ -z "${1+x}" ]; then
  log "Error: Missing branch pattern argument"
  log
  usage
  exit 1
fi
pattern=$1

git for-each-ref --format='%(refname:short)' refs/heads/ \
  | grep "$pattern" \
  | xargs git push --atomic --set-upstream origin
