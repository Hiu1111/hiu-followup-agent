#!/usr/bin/env bash
# One-time setup on macOS/Linux: create a virtual environment and install dependencies.
set -euo pipefail
cd "$(dirname "$0")"
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
echo "Setup complete. Next: put credentials.json here, copy config.example.json to config.json, then run: .venv/bin/python main.py"
