#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

usage() {
  cat <<EOF
Find pods in Kubernetes without CPU/memory resource requests/limits.

Pods are grouped by owner, e.g. a deployment or job.

Examples:

Get a filtered list of offending pods in \`instant-payments\`:
  ./k8s_resources.sh --output filtered --namespace instant-payments

Save some raw output for every namespace:
  ./k8s_resources.sh --output raw > tmp/raw_output

Get a minimal output from a saved raw file:
  ./k8s_resources.sh --output minimal -f ./tmp/raw_output

Dependencies:

- jq

Optional:

  -f --file                FILE    - File to read raw input from.
                                     Defaults to using kubectl.

  -o --output              OUT     - One of: raw, full, filtered, minimal.
                                     Default: minimal.

  -n --namespace           NS      - The kubernetes namespace. No effect if reading from file.
                                     Default: all namespaces.

     --ignore-cpu-limit            - Ignore CPU limits. Throttling is a bitch.
     --ignore-mem-limit            - Ignore memory limits.
     --ignore-namespaces   NS      - Comma separated list of namespaces to ignore.

  -h --help                        - Print this help and exit
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
  output="minimal"
  namespace=""
  file=""
  ignore_cpu_limit=false
  ignore_mem_limit=false
  ignore_namespaces_comma_sep=""

  while [[ $# -gt 0 ]]; do
    local key="$1"

    case $key in
    -o | --output)
      if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
        if ! [[ "$2" =~ ^(raw|full|filtered|minimal)$ ]]; then
          log "Output (-o, --output) must be one of: raw, full, filtered, minimal"
          exit 1
        fi
        output="$2"
        shift
      else
        log "Argument for $1 is missing"
        exit 1
      fi
      ;;
    -n | --namespace)
      if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
        namespace="$2"
        shift
      else
        log "Argument for $1 is missing"
        exit 1
      fi
      ;;
    -f | --file)
      if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
        file="$2"
        shift
      else
        log "Argument for $1 is missing"
        exit 1
      fi
      ;;
    --ignore-cpu-limit)
      ignore_cpu_limit=true
      ;;
    --ignore-mem-limit)
      ignore_mem_limit=true
      ;;
    --ignore-namespaces)
      if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
        ignore_namespaces_comma_sep="$2"
        shift
      else
        log "Argument for $1 is missing"
        exit 1
      fi
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

  # From comma-separated to an array
  IFS="," read -r -a ignore_namespaces_array <<<"$ignore_namespaces_comma_sep"
  # From array to JSON list
  ignore_namespaces=$(jq --compact-output --null-input '$ARGS.positional' --args -- "${ignore_namespaces_array[@]+"${ignore_namespaces_array[@]}"}")
}

# Check any required dependencies exist
check_environment() {
  local req_commands="jq" # space-separated list
  for comm in $req_commands; do
    if ! command -v "$comm" &>/dev/null; then
      log "🙈 Required command '$comm' could not be found"
      exit 1
    fi
  done
}

run() {
  if [ -n "$namespace" ]; then
    namespace_flag=(--namespace "$namespace")
  else
    namespace_flag=(--all-namespaces)
  fi

  if [ -n "$file" ]; then
    set +o xtrace
    raw=$(<"$file")
    if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi
  else
    raw=$(kubectl get pod "${namespace_flag[@]}" --sort-by='.metadata.name' -o json)
  fi

  if [ "$output" = "raw" ]; then
    echo "$raw"
    exit
  fi

  full=$(
    jq -r \
      --arg IGNORE_CPU_LIMIT "${ignore_cpu_limit}" \
      --arg IGNORE_MEM_LIMIT "${ignore_mem_limit}" \
      --argjson IGNORE_NAMESPACES "${ignore_namespaces}" \
      '[
        .items[] | {
          namespace: .metadata.namespace,
          owner: .metadata.name | sub("(-\\d*-)?(-[\\w\\d]*){2}$"; ""), # Removes suffix for deployments/jobs
          pod: .metadata.name,
          containers: .spec.containers | map({
            container: .name,
            cpu_req: .resources.requests.cpu,
            mem_req: .resources.requests.memory,
          } + if $IGNORE_CPU_LIMIT == "false" then {
            cpu_limit: .resources.limits.cpu
          } else {} end + if $IGNORE_MEM_LIMIT == "false" then {
            mem_limit: .resources.limits.memory
          } else {} end)
        }
      ]
      | map(select(.namespace | IN($IGNORE_NAMESPACES[]) | not))
      | unique_by(.owner)' <<<"$raw"
  )
  if [ "$output" = "full" ]; then
    echo "$full"
    exit
  fi

  filtered=$(jq -r '.[].containers |= map(select(any(. == null))) | map(select(.containers | length > 0)) | sort_by(.namespace)' <<<"$full")
  if [ "$output" = "filtered" ]; then
    echo "$filtered"
    exit
  fi

  minimal=$(jq -r '.[].containers |= map(.container)' <<<"$filtered")
  if [ "$output" = "minimal" ]; then
    echo "$minimal"
    exit
  fi
}

parse_params "$@"
check_environment
run
