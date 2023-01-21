#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

RUST_LOG=info,sqlx=info \
RUST_BACKTRACE=1 \
cargo test --test '*' "${1:-}" -- --nocapture
