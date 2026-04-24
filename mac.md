reset:
```
bash -lc 'pkill -f openjarvis_voice.py 2>/dev/null || true; pkill -f openjarvis_voice_wrapper.sh 2>/dev/null || true; sleep 0.2; rm -rf "$HOME/Desktop/openjarvis" "$HOME/openjarvis" "$HOME/openjarvis_voice.py" "$HOME/openjarvis-voice.log" "$HOME/openjarvis-voice.pid" "$HOME/start_with_voice.sh" "$HOME/stop_with_voice.sh" "$HOME/start_foreground_with_voice.sh" "$HOME/openjarvis_voice_wrapper.sh" "$HOME/openjarvis_voice_wake_patch.py" "$HOME/.openjarvis_voice_venv"; echo "reset-openjarvis: done"'
```
```
bash -lc 'T="$HOME/Desktop/openjarvis"; if [ -e "$T" ] && [ -n "$(ls -A "$T" 2>/dev/null)" ]; then T="${T}-$(date +%Y%m%d_%H%M%S)"; fi; mkdir -p "$T/data" "$T/venv"; python3 -m venv "$T/venv"; "$T/venv/bin/python" -m pip install --upgrade pip >/dev/null 2>&1 || true; cat > "$T/data/openjarvis_voice.py" <<'"PY"' && chmod +x "$T/data/openjarvis_voice.py" && echo "install-openjarvis: created at $T"\n#!/usr/bin/env python3\n# placeholder: replace with your script when ready\nprint(\"OpenJarvis isolated placeholder: $T/data/openjarvis_voice.py\")\nPY'
```
