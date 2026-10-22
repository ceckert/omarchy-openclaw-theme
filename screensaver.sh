#!/bin/bash

# Puts the OpenClaw screensaver art in place of the user's own, or puts theirs
# back. Omarchy keeps the screensaver in branding, not in the theme, so the art
# stays after switching to another theme until `restore` is run.
#
#   bash ~/.config/omarchy/themes/openclaw/screensaver.sh install
#   bash ~/.config/omarchy/themes/openclaw/screensaver.sh restore

set -euo pipefail

theme_art="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/screensaver.txt"
art="$HOME/.config/omarchy/branding/screensaver.txt"
backup="$art.before-openclaw"

case "${1:-}" in
install)
  mkdir -p "${art%/*}"
  # Keep the first backup: running install twice must not save our own art as theirs.
  if [[ -f $art && ! -f $backup ]] && ! cmp -s "$art" "$theme_art"; then
    cp "$art" "$backup"
  fi
  cp "$theme_art" "$art"
  echo "OpenClaw screensaver installed. Undo with: bash $0 restore"
  ;;
restore)
  if [[ -f $backup ]]; then
    mv "$backup" "$art"
  else
    cp "$OMARCHY_PATH/logo.txt" "$art"
  fi
  echo "Screensaver restored."
  ;;
*)
  echo "Usage: bash $0 <install|restore>" >&2
  exit 1
  ;;
esac

if [[ ${2:-} == "--preview" ]]; then
  omarchy-launch-screensaver force
fi
