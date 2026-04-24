reset:
```
bash -lc 'pkill -f openjarvis_voice.py 2>/dev/null || true; pkill -f openjarvis_voice_wrapper.sh 2>/dev/null || true; sleep 0.2; rm -rf "$HOME/Desktop/openjarvis" "$HOME/openjarvis" "$HOME/openjarvis_voice.py" "$HOME/openjarvis-voice.log" "$HOME/openjarvis-voice.pid" "$HOME/start_with_voice.sh" "$HOME/stop_with_voice.sh" "$HOME/start_foreground_with_voice.sh" "$HOME/openjarvis_voice_wrapper.sh" "$HOME/openjarvis_voice_wake_patch.py" "$HOME/.openjarvis_voice_venv"; echo "reset-openjarvis: done"'
```
```
bash -lc 'T="$HOME/Desktop/openjarvis"; if [ -e "$T" ] && [ -n "$(ls -A "$T" 2>/dev/null)" ]; then T="${T}-$(date +%Y%m%d_%H%M%S)"; fi; mkdir -p "$T/data"; python3 -m venv "$T/venv"; "$T/venv/bin/python" -m pip install --upgrade pip >/dev/null 2>&1 || true; "$T/venv/bin/python" -m pip install flask requests >/dev/null 2>&1 || true; cat > "$T/data/openjarvis.py" <<'"PY"'
from flask import Flask, render_template_string
app = Flask(__name__)
TEMPLATE = """<!doctype html>
<html>
  <head><meta charset="utf-8"><title>OpenJarvis</title></head>
  <body>
    <h1>OpenJarvis UI</h1>
    <p>This is the isolated OpenJarvis placeholder UI. Replace this file with your real app when ready.</p>
  </body>
</html>
"""
@app.route("/")
def index():
    return render_template_string(TEMPLATE)
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
PY
cat > "$T/start.sh" <<'"SH"'
#!/usr/bin/env bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV="$BASE_DIR/venv"
SCRIPT="$BASE_DIR/data/openjarvis.py"
LOG="$BASE_DIR/openjarvis.log"
PID="$BASE_DIR/openjarvis.pid"
if [ ! -x "$VENV/bin/python" ]; then
  echo "Venv missing at $VENV"
  exit 1
fi
nohup "$VENV/bin/python" "$SCRIPT" >>"$LOG" 2>&1 & echo $! >"$PID"
sleep 0.8
open "http://127.0.0.1:5000/"
echo "started (pid $(cat "$PID"))"
SH
chmod +x "$T/start.sh"
cat > "$T/stop.sh" <<'"SH2"'
#!/usr/bin/env bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PID="$BASE_DIR/openjarvis.pid"
if [ -f "$PID" ]; then
  kill "$(cat "$PID")" 2>/dev/null || true
  rm -f "$PID"
  echo "stopped"
else
  pkill -f "$BASE_DIR/data/openjarvis.py" 2>/dev/null || true
  echo "stopped (pkill)"
fi
SH2
chmod +x "$T/stop.sh"
echo "install-openjarvis: created at $T; start with: $T/start.sh"
```
