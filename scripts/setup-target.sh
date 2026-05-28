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

echo "Creating app directory..."
sudo mkdir -p /opt/tasktrack/static
sudo chown -R "$USER":"$USER" /opt/tasktrack
echo "App directory created."

echo "Installing systemd unit..."
sudo tee /etc/systemd/system/tasktrack.service > /dev/null << 'EOF'
[Unit]
Description=TaskTrack Web Application
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=Iwan
Restart=on-failure
RestartSec=5s
ExecStartPre=-/usr/bin/docker stop tasktrack
ExecStartPre=-/usr/bin/docker rm tasktrack
ExecStart=/usr/bin/docker run --name tasktrack \
    --network host \
    -e DB_HOST=127.0.0.1 \
    ghcr.io/iwanbpe/tasktrack:stable
ExecStop=/usr/bin/docker stop tasktrack

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tasktrack
echo "Systemd unit installed."

echo "=== Target node setup complete ==="
