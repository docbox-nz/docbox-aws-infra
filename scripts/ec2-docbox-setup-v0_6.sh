#!/bin/bash

# ===
# This setup script is intended to be run on the EC2 instance
# that will be running the docbox API.
# ===

# Variables injected into the template
PROXY_HOST="${proxy_host}"
PROXY_PORT="${proxy_port}"
PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"

# Configure dnf and system to use proxy
# (Will be required to reach the internet)
configure_proxy() {
    if ! grep -q "^proxy=" /etc/dnf/dnf.conf 2>/dev/null; then
        echo "proxy=$PROXY_URL" >> /etc/dnf/dnf.conf
    else
        sed -i "s|^proxy=.*|proxy=$PROXY_URL|" /etc/dnf/dnf.conf
    fi

    # Set environment proxy variables for the session
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"

    # Make proxy settings persistent for all users
    cat >>/etc/environment <<EOF
http_proxy=$PROXY_URL
https_proxy=$PROXY_URL
HTTP_PROXY=$PROXY_URL
HTTPS_PROXY=$PROXY_URL
EOF
}

# Wait until the EC2 container has networking
# (When terraform is setting up this may not happen immediately)
wait_for_network() {
    # Wait until the network is up
    until curl -sSf https://www.google.com >/dev/null; do
        echo "Waiting for network..."
        sleep 5
    done
}

# Set the system timezone to NZST
set_timezone() {
    sudo timedatectl set-timezone Pacific/Auckland
}

# Install required dependencies
install_dependencies() {
    # Install updates
    echo "Installing updates"
    sudo dnf update -y

    # Install poppler
    echo "Installing dependencies"
    sudo dnf install -y poppler poppler-utils poppler-data
}

# Create the docbox directory, download docbox binary and setup the docbox service
setup_docbox_service() {
    local TMP_SERVER_PATH="/tmp/docbox"
    local SERVER_PATH="/docbox/app"

    # Download docbox server binary
    echo "Downloading docbox server"
    curl -L -o $TMP_SERVER_PATH https://github.com/docbox-nz/docbox/releases/latest/download/docbox-aarch64-linux-gnu

    # Ensure the docbox directory exists
    sudo mkdir /docbox

    # Move docbox server binary
    sudo mv $TMP_SERVER_PATH $SERVER_PATH

    # Ensure the binary has execute permissions
    sudo chmod +x $SERVER_PATH

    # Create service for docbox
    echo "Creating docbox service"
    cat <<EOF | sudo tee /etc/systemd/system/docbox.service >/dev/null
[Unit]
Description=DocBox service
After=network-online.target

[Service]
Type=simple
ExecStart=/docbox/app
Restart=always
WorkingDirectory=/docbox
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    echo "Reloading systemd manager configuration..."

    # Reload the services
    sudo systemctl daemon-reload

    # Enable automatic startup of the services
    sudo systemctl enable docbox.service

    # Start the services
    sudo systemctl start docbox.service

    # Create updater script
    cat <<EOF | sudo tee /docbox/update.sh >/dev/null
TMP_SERVER_PATH="/tmp/docbox"
SERVER_PATH="/docbox/app"
SERVER_PATH_ALT="/docbox/app-previous"

# Download office converter server binary
curl -L -o \$TMP_SERVER_PATH https://github.com/docbox-nz/docbox/releases/latest/download/docbox-aarch64-linux-gnu

# Move current docbox server binary
sudo mv \$SERVER_PATH \$SERVER_PATH_ALT

# Move the new docbox server binary
sudo mv \$TMP_SERVER_PATH \$SERVER_PATH

# Ensure the binary has execute permissions
sudo chmod +x \$SERVER_PATH

# Restart the service
sudo systemctl restart docbox.service
EOF

    # Make updater script executable
    sudo chmod +x /docbox/update.sh
}

# Setup a 1GB
setup_swap() {
    # Allocate 1GB swap file
    sudo fallocate -l 1G /swapfile

    # Set swap file permissions
    sudo chmod 600 /swapfile

    # Set the swap area
    sudo mkswap /swapfile

    # Enable the swap file
    sudo swapon /swapfile

    # Persist the new swap file
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
}

configure_proxy
wait_for_network
set_timezone
install_dependencies
setup_docbox_service
setup_swap
