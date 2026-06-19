#!/usr/bin/env bash
set -euo pipefail

PORT=5173
cd "$(dirname "$0")"

echo "Stopping anything on port $PORT..."
lsof -ti:"$PORT" | xargs kill -9 2>/dev/null || true
sleep 1

echo "Starting blobfiles on http://localhost:$PORT ..."
echo "Tip: keep this terminal open — press R here to hot restart."
flutter run -d chrome --web-port "$PORT" \
  --web-browser-flag "--disable-cache" \
  --web-browser-flag "--disable-application-cache"