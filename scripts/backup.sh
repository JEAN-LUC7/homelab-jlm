#!/usr/bin/env bash
set -euo pipefail

DISQUE=/mnt/sauvegardes
export RESTIC_REPOSITORY="$DISQUE/restic"
export RESTIC_PASSWORD_FILE="$HOME/.restic-password"

if [ ! -f "$DISQUE/.disque_ok" ]; then
  echo "$(date) ERREUR : disque de sauvegarde absent" >&2
  exit 1
fi

restic backup "$HOME/homelab" "$HOME/test-data"
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune