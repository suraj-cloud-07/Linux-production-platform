#!/bin/bash

SERVICE="linuxops.service"
HEALTH_URL="http://127.0.0.1:8000/health"
MEMORY_LIMIT_MB=200

echo "================================="
echo "   LINUXOPS SERVICE MONITOR"
echo "================================="

# 1. Check service status
if systemctl is-active --quiet "$SERVICE"; then
    echo "[OK] Service is running"
else
    echo "[CRITICAL] Service is not running"
fi

# 2. Check API health
HTTP_CODE=$(curl -s -o /dev/null \
-w "%{http_code}" --max-time 3 "$HEALTH_URL")

if [ "$HTTP_CODE" = "200" ]; then
    echo "[OK] API health check passed"
else
    echo "[CRITICAL] API health check failed"
fi

# 3. Check restart count
RESTARTS=$(systemctl show "$SERVICE" \
-p NRestarts --value)

echo "[INFO] Service restart count: $RESTARTS"

if [ "$RESTARTS" -gt 0 ]; then
    echo "[WARNING] Service has restarted previously"
fi

# 4. Check memory usage
PID=$(systemctl show "$SERVICE" -p MainPID --value)

if [ "$PID" -gt 0 ]; then
    MEMORY_KB=$(ps -p "$PID" -o rss=)
    MEMORY_MB=$((MEMORY_KB / 1024))

    echo "[INFO] Memory usage: ${MEMORY_MB} MB"

    if [ "$MEMORY_MB" -gt "$MEMORY_LIMIT_MB" ]; then
        echo "[WARNING] High memory usage!"
    else
        echo "[OK] Memory usage is normal"
    fi
else
    echo "[WARNING] No running process found"
fi

echo "================================="
echo "       MONITORING COMPLETE"
echo "================================="
