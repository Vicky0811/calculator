#!/usr/bin/env bash
# deploy.sh — run on EC2 by Jenkins via SSH after SCP of the JAR
set -euo pipefail

APP_DIR="/opt/calculator"
JAR="$APP_DIR/calculator.jar"
LOG="$APP_DIR/app.log"
PORT=8080

echo "[deploy] $(date) — Starting deployment"

# Stop existing process
pkill -f "calculator.jar" && echo "[deploy] Old process stopped." || echo "[deploy] No process running."
sleep 2

# Start new JAR in background
nohup java -jar "$JAR" -Dport=$PORT > "$LOG" 2>&1 &
echo "[deploy] Started PID: $!"

sleep 4
if pgrep -f "calculator.jar" > /dev/null; then
    echo "[deploy] ✅ App running on port $PORT"
else
    echo "[deploy] ❌ App failed to start — check $LOG"
    exit 1
fi
