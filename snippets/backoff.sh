#!/usr/bin/env bash

log() {
  echo -e "${1:-}" >&2
}

# If we have unpushed changes...
if [ -n "$(git log '@{u}'..)" ]; then
  max_attempts=3
  attempt=1

  log
  log "⬆️ Push changes..."
  until git push -u origin master; do
    log
    log "😳 ... that didn't work"

    ((attempt = attempt + 1))

    if ((attempt > max_attempts)); then
      log
      log "😞 Giving up"
      exit 1
    else
      seconds=$((((RANDOM % 10) + 1) * attempt))s
      log
      log "😴 Sleep for ${seconds}"
      sleep ${seconds}

      log "🔝 Rebase onto latest config"
      git pull --rebase

      log "#️⃣ Attempt ${attempt} to push..."
    fi
  done
  log "🌳 Successfully pushed"
else
  log
  log "🌱 No changes to push"
fi
