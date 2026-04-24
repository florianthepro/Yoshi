#!/usr/bin/env bash
# clean-isolated-openjarvis.sh
# macOS: create a fresh, isolated OpenJarvis installation under ~/Desktop/openjarvis
# - Does NOT touch or remove any existing OpenJarvis installations elsewhere.
# - Does NOT stop any running processes.
# - Creates an isolated venv and data folder and start/stop scripts.
# - Does NOT start any services automatically.

set -euo pipefail

# Base desired path
BASE_DESIRED="$HOME/Desktop/openjarvis"

# If the desired path exists and is non-empty, create a timestamped alternative to avoid touching anything.
if [ -e "$BASE_DESIRED" ]; then
  if [ -d "$BASE_DESIRED" ] && [ -z "$(ls -A "$BASE_DESIRED" 2>/dev/null)" ]; then
    TARGET="$BASE_DESIRED"
  else
    TS=$(date +%Y%m%d_%H%M%S)
    TARGET="${BASE_DESIRED}-${TS}"
    echo "Note: $BASE_DESIRED already exists and is not empty."
    echo "Creating isolated installation at: $TARGET"
  fi
else
  TARGET="$BASE_DESIRED"
fi

DATA="$TARGET/data"
VENV="$TARGET/venv"
LOG="$TARGET/setup.log"

mkdir -p "$DATA" "$VENV"
touch "$LOG"

echo "=== clean-isolated-openjarvis ===" | tee -a "$LOG"
echo "Isolated install target: $TARGET" | tee -a "$LOG"
echo "Data dir: $DATA" | tee -a "$LOG"
echo "Venv dir: $VENV" | tee -a "$LOG"
echo

# Create placeholder openjarvis_voice.py only if not present
if [ ! -f "$DATA/openjarvis_voice.py" ]; then
  cat > "$DATA/openjarvis_voice.py" <<'PY'
#!/usr/bin/env python3
# placeholder openjarvis_voice.py
# This is a minimal placeholder. Replace with your real script if/when ready.
def main():
    print("OpenJarvis placeholder (isolated install). Replace data/openjarvis_voice.py with your real script.")
if __name__ == "__main__":
    main()
PY
  chmod +x "$DATA/openjarvis_voice.py"
  echo "Created placeholder: $DATA/openjarvis_voice.py" | tee -a "$LOG"
else
  echo "Skipped creating placeholder: $DATA/openjarvis_voice.py already exists" | tee -a "$LOG"
fi

# Ensure models directory exists
if [ ! -d "$DATA/models" ]; then
  mkdir -p "$DATA/models"
  echo "Created models directory: $DATA/models" | tee -a "$LOG"
else
  echo "Models directory exists: $DATA/models (skipped)" | tee -a "$LOG"
fi

# Create isolated venv if missing (idempotent)
if [ ! -x "$VENV/bin/python" ]; then
  echo "Creating Python venv at $VENV" | tee -a "$LOG"
  python3 -m venv "$VENV"
  "$VENV/bin/python" -m pip install --upgrade pip >/dev/null 2>&1 || true
  echo "Created venv (minimal). You can install packages into $VENV as needed." | tee -a "$LOG"
else
  echo "Venv already exists at $VENV (skipped)" | tee -a "$LOG"
fi

# Create start/stop scripts in TARGET (do not overwrite if present)
mkdir -p "$TARGET"

# start background
if [ ! -f "$TARGET/start_with_voice.sh" ]; then
cat > "$TARGET/start_with_voice.sh" <<'SH_BG'
#!/usr/bin/env bash
# Start OpenJarvis in background using the isolated venv in the same folder
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$BASE_DIR/data"
VENV_DIR="$BASE_DIR/venv"
OPENVOICE="$DATA_DIR/openjarvis_voice.py"
LOG="$BASE_DIR/openjarvis.log"
PIDF="$BASE_DIR/openjarvis.pid"
if [ ! -x "$VENV_DIR/bin/python" ]; then
  echo "Venv not found at $VENV_DIR. Run the setup script first."
  exit 1
fi
# install minimal deps if desired (idempotent)
"$VENV_DIR/bin/python" -m pip install --upgrade pip >/dev/null 2>&1 || true
if [ -f "$PIDF" ]; then
  kill "$(cat "$PIDF")" 2>/dev/null || true
  rm -f "$PIDF"
fi
pkill -f "$OPENVOICE" 2>/dev/null || true
sleep 0.2
nohup bash -lc 'while true; do "'"$VENV_DIR"'/bin/python" "'"$OPENVOICE"'" || true; sleep 0.5; done' > "$LOG" 2>&1 & echo $! > "$PIDF"
echo "Started OpenJarvis background process. PID file: $PIDF, Log: $LOG"
SH_BG
  chmod +x "$TARGET/start_with_voice.sh"
  echo "Created start script: $TARGET/start_with_voice.sh" | tee -a "$LOG"
else
  echo "Start script exists: $TARGET/start_with_voice.sh (skipped)" | tee -a "$LOG"
fi

# stop
if [ ! -f "$TARGET/stop_with_voice.sh" ]; then
cat > "$TARGET/stop_with_voice.sh" <<'SH_STOP'
#!/usr/bin/env bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PIDF="$BASE_DIR/openjarvis.pid"
if [ -f "$PIDF" ]; then
  kill "$(cat "$PIDF")" 2>/dev/null || true
  rm -f "$PIDF"
  echo "Stopped process from $PIDF"
else
  echo "No PID file; attempting pkill by script name"
  pkill -f openjarvis_voice.py 2>/dev/null || true
  echo "pkill attempted"
fi
SH_STOP
  chmod +x "$TARGET/stop_with_voice.sh"
  echo "Created stop script: $TARGET/stop_with_voice.sh" | tee -a "$LOG"
else
  echo "Stop script exists: $TARGET/stop_with_voice.sh (skipped)" | tee -a "$LOG"
fi

# foreground start
if [ ! -f "$TARGET/start_foreground_with_voice.sh" ]; then
cat > "$TARGET/start_foreground_with_voice.sh" <<'SH_FG'
#!/usr/bin/env bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$BASE_DIR/data"
VENV_DIR="$BASE_DIR/venv"
OPENVOICE="$DATA_DIR/openjarvis_voice.py"
if [ ! -x "$VENV_DIR/bin/python" ]; then
  echo "Venv not found at $VENV_DIR. Run the setup script first."
  exit 1
fi
"$VENV_DIR/bin/python" -m pip install --upgrade pip >/dev/null 2>&1 || true
echo "Starting OpenJarvis in foreground. Press Ctrl+C to stop."
while true; do
  "$VENV_DIR/bin/python" "$OPENVOICE" || true
  sleep 0.5
done
SH_FG
  chmod +x "$TARGET/start_foreground_with_voice.sh"
  echo "Created foreground start script: $TARGET/start_foreground_with_voice.sh" | tee -a "$LOG"
else
  echo "Foreground start script exists: $TARGET/start_foreground_with_voice.sh (skipped)" | tee -a "$LOG"
fi

# Final summary
echo
echo "=== clean-isolated-openjarvis complete ===" | tee -a "$LOG"
echo "Isolated install location: $TARGET" | tee -a "$LOG"
echo "Data directory: $DATA" | tee -a "$LOG"
echo "Venv directory: $VENV" | tee -a "$LOG"
echo "Start scripts: $TARGET/start_with_voice.sh  $TARGET/start_foreground_with_voice.sh" | tee -a "$LOG"
echo "Stop script:   $TARGET/stop_with_voice.sh" | tee -a "$LOG"
echo
echo "Notes:"
echo "- This script did NOT touch any existing OpenJarvis installations elsewhere on your system."
echo "- Replace $DATA/openjarvis_voice.py with your real script when ready."
echo "- To start (foreground): $TARGET/start_foreground_with_voice.sh"
echo "- To start (background): $TARGET/start_with_voice.sh"
echo "- To stop: $TARGET/stop_with_voice.sh"
