#!/bin/sh
set -e

echo "Running migrations..."
python migration.py

echo "Starting gunicorn..."
exec gunicorn --bind 0.0.0.0:8000 --workers 2 app:app
