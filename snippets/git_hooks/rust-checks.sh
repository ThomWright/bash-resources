#!/bin/sh

set -o errexit
set -o nounset

_remote="$1"
_url="$2"

cargo fmt --check
cargo clippy --all-targets --all-features -- --deny warnings

exit 0
