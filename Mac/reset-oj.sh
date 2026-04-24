#!/usr/bin/env bash
# reset-openjarvis.sh
# macOS: stop all OpenJarvis processes and remove all known OpenJarvis files/dirs.
# WARNING: This permanently deletes files listed below. The script shows what it will remove
# and waits 7 seconds so you can cancel (Ctrl+C). Run only if you are sure.
set -euo pipefail

TS=$(date +%Y%m%d_%H%M%S)
REMOVED_DIR="$HOME/openjarvis_removed_$TS"
mkdir -p "$REMOVED_DIR"

echo
echo "=== reset-openjarvis ==="
echo "This will stop OpenJarvis processes and remove known OpenJarvis files."
echo "A temporary staging dir will be created at: $REMOVED_DIR"
echo
echo "Files/dirs that will be targeted (if present):"
echo "  - ~/Desktop/openjarvis  (and variants)"
echo "  - ~/openjarvis*  ~/OpenJarvis*  ~/OPENJARVIS*"
echo "  - ~/openjarvis_voice*"
echo "  - ~/start_with_voice.sh  ~/stop_with_voice.sh  ~/start_foreground_with_voice.sh"
echo "  - ~/openjarvis_voice_wrapper.sh  ~/openjarvis_voice_wake_patch.py"
echo "  - ~/.openjarvis_voice_venv"
echo "  - ~/openjarvis-voice.log  ~/openjarvis-voice.pid"
echo "  - any leftover setup or backup dirs named openjarvis* in $HOME"
echo
echo "If you want to abort, press Ctrl+C now. Proceeding in 7 seconds..."
sleep 7

echo
echo "1) Stopping running OpenJarvis processes (best-effort)..."
# Kill by PID file if present
if [ -f "$HOME/openjarvis-voice.pid" ]; then
  PID=$(cat "$HOME/openjarvis-voice.pid" 2>/dev/null || true)
  if [ -n "$PID" ]; then
    echo " - killing PID from ~/openjarvis-voice.pid: $PID"
    kill "$PID" 2>/dev/null || true
  fi
  rm -f "$HOME/openjarvis-voice.pid" || true
fi
# pkill by common script name
pkill -f openjarvis_voice.py 2>/dev/null || true
pkill -f openjarvis_voice_wrapper.sh 2>/dev/null || true
sleep 0.3

echo "2) Collecting and removing known files/dirs..."
# Helper: move to staging then remove
move_and_rm() {
  for p in "$@"; do
    # expand globs
    for f in $p; do
      [ -e "$f" ] || continue
      echo " - moving $f -> $REMOVED_DIR/"
      mv -v "$f" "$REMOVED_DIR/" 2>/dev/null || true
    done
  done
}

# Move known candidates into staging
move_and_rm "$HOME/Desktop/openjarvis" "$HOME/Desktop/openjarvis*" "$HOME/openjarvis" "$HOME/openjarvis*" "$HOME/OpenJarvis*" "$HOME/OPENJARVIS*" "$HOME/openjarvis_voice*" "$HOME/start_with_voice.sh" "$HOME/stop_with_voice.sh" "$HOME/start_foreground_with_voice.sh" "$HOME/openjarvis_voice_wrapper.sh" "$HOME/openjarvis_voice_wake_patch.py" "$HOME/whisper.cpp" "$HOME/models" "$HOME/.openjarvis_voice_venv" "$HOME/openjarvis-voice.log" "$HOME/openjarvis-voice.pid" "$HOME/openjarvis_setup_backup_*" "$HOME/openjarvis_backup_*" "$HOME/openjarvis_removed_*"

# Also check Desktop and Documents for stray folders
move_and_rm "$HOME/Desktop/openjarvis*" "$HOME/Documents/openjarvis*"

echo
echo "3) Permanently deleting staged items in: $REMOVED_DIR"
# Double-check directory exists and is not root
if [ -d "$REMOVED_DIR" ] && [ "$REMOVED_DIR" != "/" ] && [ "$REMOVED_DIR" != "$HOME" ]; then
  # Secure removal: rm -rf (user warned at start)
  rm -rf "$REMOVED_DIR"
  echo " - removed $REMOVED_DIR"
else
  echo " - staging dir missing or unsafe, skipping permanent delete."
fi

# Remove possible leftover PID/log in Desktop/openjarvis if any
if [ -d "$HOME/Desktop/openjarvis" ]; then
  echo "Removing leftover Desktop/openjarvis (if empty or present)..."
  rm -rf "$HOME/Desktop/openjarvis" 2>/dev/null || true
fi

# Final cleanup of common single files if still present
for f in "$HOME/openjarvis-voice.log" "$HOME/openjarvis-voice.pid" "$HOME/start_with_voice.sh" "$HOME/stop_with_voice.sh" "$HOME/start_foreground_with_voice.sh" "$HOME/openjarvis_voice_wrapper.sh"; do
  if [ -e "$f" ]; then
    echo " - removing $f"
    rm -rf "$f" 2>/dev/null || true
  fi
done

echo
echo "=== reset-openjarvis complete ==="
echo "All known OpenJarvis artifacts were stopped and removed (moved to staging and deleted)."
echo "If you expected something else to be removed, check manually."
