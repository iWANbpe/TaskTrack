#!/bin/bash
set -e

TARGET_HOST="${TARGET_HOST:-192.168.1.104}"
TARGET_USER="${TARGET_USER:-Iwan}"
IMAGE="${IMAGE:-ghcr.io/iwanbpe/tasktrack:stable}"

echo "=== Deploying $IMAGE to $TARGET_USER@$TARGET_HOST ==="

ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_HOST" bash << EOF
set -e

echo "Pulling image $IMAGE..."
docker pull $IMAGE

echo "Restarting tasktrack service..."
sudo systemctl restart tasktrack

echo "Waiting for service to start..."
sleep 5

echo "Service status:"
sudo systemctl status tasktrack --no-pager
EOF

echo "=== Deploy complete ==="
