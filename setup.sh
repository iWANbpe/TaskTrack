#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run via sudo!"
  exit 1
fi

set -e

ORIGINAL_USER=${SUDO_USER:-$(whoami)}
VARIANT_N=13 
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
TARGET_DIR="/home/student/TaskTrack"

users=("student" "teacher" "operator")
DEFAULT_PASS="12345678"

for user in "${users[@]}"; do
    if id "$user" &>/dev/null; then
        echo "User $user already exists."
    
    else
        if getent group "$user" &>/dev/null; then
            useradd -m -g "$user" -s /bin/bash "$user"
        else
            useradd -m -s /bin/bash "$user"
        fi
        echo "$user:$DEFAULT_PASS" | chpasswd
        passwd --expire "$user"
    fi
done

usermod -aG www-data student

if ! id "app" &>/dev/null; then
    useradd -r -s /bin/false app
fi

mkdir -p "$TARGET_DIR"
cp -r "$SCRIPT_DIR"/* "$TARGET_DIR/" || true
cd "$TARGET_DIR"

apt update
apt install -y python3 python3-pip python3-venv nginx postgresql postgresql-contrib curl git

rm -f /etc/sudoers.d/tasktrack_rules
cat << 'EOF' > /etc/sudoers.d/tasktrack_rules
student ALL=(ALL:ALL) ALL
teacher ALL=(ALL:ALL) ALL

operator ALL=(ROOT) NOPASSWD: /usr/bin/systemctl start mywebapp.service, \
                             /usr/bin/systemctl stop mywebapp.service, \
                             /usr/bin/systemctl restart mywebapp.service, \
                             /usr/bin/systemctl status mywebapp.service, \
                             /usr/bin/systemctl reload nginx
EOF
chmod 0440 /etc/sudoers.d/tasktrack_rules
visudo -c -f /etc/sudoers.d/tasktrack_rules

echo "$VARIANT_N" > /home/student/gradebook
chown student:student /home/student/gradebook
chmod 644 /home/student/gradebook

systemctl start postgresql
systemctl enable postgresql

sudo -i -u postgres psql -c "CREATE USER myuser WITH PASSWORD '123456789';" || true
sudo -i -u postgres psql -c "CREATE DATABASE tasktrack_db OWNER myuser;" || true
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE tasktrack_db TO myuser;" || true

rm -rf "$TARGET_DIR/.venv"
rm -f "$TARGET_DIR/mywebapp.sock"

chown -R app:www-data "$TARGET_DIR"
chmod -R 750 "$TARGET_DIR"

sudo -u app python3 -m venv "$TARGET_DIR/.venv"
sudo -u app "$TARGET_DIR/.venv/bin/pip" install --upgrade pip

REQ_FILE="$TARGET_DIR/etc/mywebapp/requiraments.txt"
if [ -f "$REQ_FILE" ]; then
    sudo -u app "$TARGET_DIR/.venv/bin/pip" install -r "$REQ_FILE"
fi
sudo -u app "$TARGET_DIR/.venv/bin/pip" install gunicorn

eval_dir="$TARGET_DIR"
while [ "$eval_dir" != "/" ]; do
    chmod o+x "$eval_dir"
    eval_dir=$(dirname "$eval_dir")
done

cp "$TARGET_DIR/etc/systemd/system/mywebapp.service" /etc/systemd/system/mywebapp.service
cp "$TARGET_DIR/etc/nginx/sites-available/mywebapp" /etc/nginx/sites-available/mywebapp

if [ ! -f "/etc/nginx/sites-enabled/mywebapp" ]; then
    ln -s /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
fi

if [ -f "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default
fi

systemctl daemon-reload
systemctl enable mywebapp.service
systemctl restart mywebapp.service

sleep 1
if [ -S "$TARGET_DIR/mywebapp.sock" ]; then
    chmod 660 "$TARGET_DIR/mywebapp.sock"
    chown app:www-data "$TARGET_DIR/mywebapp.sock"
fi

systemctl restart nginx

if [ "$ORIGINAL_USER" != "root" ] && [ "$ORIGINAL_USER" != "student" ] && [ "$ORIGINAL_USER" != "teacher" ] && [ "$ORIGINAL_USER" != "operator" ]; then
    usermod -L "$ORIGINAL_USER"
fi
