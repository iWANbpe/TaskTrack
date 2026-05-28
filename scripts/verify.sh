#!/bin/bash
set -e

TARGET_HOST="${TARGET_HOST:-192.168.1.104}"
TARGET_USER="${TARGET_USER:-Iwan}"

echo "=== Verifying deployment on $TARGET_HOST ==="

FAILURES=0

echo "--- Checking /health/alive..."
ALIVE=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET_HOST/health/alive")
if [ "$ALIVE" = "200" ]; then
    echo "✓ /health/alive returned 200"
else
    echo "✗ /health/alive returned $ALIVE (expected 200)"
    FAILURES=$((FAILURES + 1))
fi

echo "--- Checking /health/ready..."
READY=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET_HOST/health/ready")
if [ "$READY" = "200" ]; then
    echo "✓ /health/ready returned 200"
else
    echo "✗ /health/ready returned $READY (expected 200)"
    FAILURES=$((FAILURES + 1))
fi

echo "--- Checking Nginx configuration..."
ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST" bash << 'ENDSSH'
set -e

sudo nginx -t 2>&1
echo "✓ Nginx config is valid"

if grep -q "proxy_pass" /etc/nginx/sites-available/tasktrack; then
    echo "✓ Nginx proxy_pass configured"
else
    echo "✗ Nginx proxy_pass not found"
    exit 1
fi

if grep -q "proxy_set_header Host" /etc/nginx/sites-available/tasktrack; then
    echo "✓ Nginx proxy headers configured"
else
    echo "✗ Nginx proxy headers not configured"
    exit 1
fi
ENDSSH

echo "--- Checking systemd service..."
SERVICE_STATUS=$(ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST" \
    "systemctl is-active tasktrack")
if [ "$SERVICE_STATUS" = "active" ]; then
    echo "✓ tasktrack service is active"
else
    echo "✗ tasktrack service is $SERVICE_STATUS (expected active)"
    FAILURES=$((FAILURES + 1))
fi

echo "--- Checking /tasks endpoint..."
TASKS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Accept: application/json" "http://$TARGET_HOST/tasks")
if [ "$TASKS_CODE" = "200" ]; then
    echo "✓ /tasks returned 200"
else
    echo "✗ /tasks returned $TASKS_CODE (expected 200)"
    FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "=== ✓ Verification PASSED ==="
    exit 0
else
    echo "=== ✗ Verification FAILED ($FAILURES check(s) failed) ==="
    exit 1
fi
