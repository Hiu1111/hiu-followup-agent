#!/usr/bin/env bash
# Runs the follow-up agent once (macOS/Linux). Schedule it daily with cron:
#   crontab -e
#   0 8 * * * /full/path/to/hiu-followup-agent/run_agent.sh >> /full/path/to/hiu-followup-agent/agent.log 2>&1
set -euo pipefail
cd "$(dirname "$0")"
if [ -x .venv/bin/python ]; then .venv/bin/python main.py; else python3 main.py; fi
