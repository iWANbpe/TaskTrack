#!/bin/bash
set -e

echo "=== Setting up target node ==="

if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker "$USER"
    echo "Docker installed."
else
    echo "Docker already installed."
fi

if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt-get install -y nginx
    echo "Nginx installed."
else
    echo "Nginx already installed."
fi

echo "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/tasktrack > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /opt/tasktrack/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/tasktrack /etc/nginx/sites-enabled/tasktrack
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
echo "Nginx configured."

echo "Creating app directory and config..."
sudo mkdir -p /opt/tasktrack/static
sudo chown -R "$USER":"$USER" /opt/tasktrack

cat > /opt/tasktrack/config.json << 'EOF'
{
  "db": {
    "dbname": "tasktrack_db",
    "user": "myuser",
    "password": "123456789",
    "host": "127.0.0.1",
    "port": "5432"
  },
  "web": {
    "host": "0.0.0.0",
    "port": 8000
  }
}
EOF
echo "App directory and config created."

echo "Starting PostgreSQL container..."
if docker ps -a --format '{{.Names}}' | grep -q '^tasktrack-db$'; then
    echo "PostgreSQL container already exists, starting..."
    docker start tasktrack-db || true
else
    docker run -d \
        --name tasktrack-db \
        --restart unless-stopped \
        -e POSTGRES_DB=tasktrack_db \
        -e POSTGRES_USER=myuser \
        -e POSTGRES_PASSWORD=123456789 \
        -p 5432:5432 \
        postgres:16-alpine
fi
echo "PostgreSQL container started."

echo "Configuring sudoers..."
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/sbin/nginx" | \
    sudo tee /etc/sudoers.d/tasktrack > /dev/null
sudo chmod 0440 /etc/sudoers.d/tasktrack
sudo visudo -c
echo "Sudoers configured."

echo "Installing systemd unit..."
sudo tee /etc/systemd/system/tasktrack.service > /dev/null << EOF
[Unit]
Description=TaskTrack Web Application
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=$USER
Restart=on-failure
RestartSec=5s
ExecStartPre=-/usr/bin/docker stop tasktrack
ExecStartPre=-/usr/bin/docker rm tasktrack
ExecStart=/usr/bin/docker run --name tasktrack \\
    --network host \\
    -v /opt/tasktrack/config.json:/app/etc/mywebapp/config.json:ro \\
    ghcr.io/iwanbpe/tasktrack:stable
ExecStop=/usr/bin/docker stop tasktrack

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tasktrack
echo "Systemd unit installed."

echo "=== Target node setup complete ==="
echo "Run 'sudo systemctl start tasktrack' to start the application."
