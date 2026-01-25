#!/bin/bash

# ===
# This setup script is intended to be run on the EC2 instance
# that will be running the docbox API.
# ===

# Variables injected into the template
PROXY_HOST="${proxy_host}"
PROXY_PORT="${proxy_port}"
PROXY_URL="http://$PROXY_HOST:$PROXY_PORT"
SECRET_NAME="${secret_name}"

# IP address for instance metadata services (IMDS)
INSTANCE_METADATA_SERVICE_IP="169.254.169.254"

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

    # Ensure directory for override exists
    sudo mkdir -p /etc/systemd/system/amazon-ssm-agent.service.d

    # Create service override to proxy AWS SSM agent traffic through the proxy server
    # (https://docs.aws.amazon.com/systems-manager/latest/userguide/configure-proxy-ssm-agent.html#ssm-agent-proxy-upstart)
    echo "Setting up AWS SSM proxying"
    cat <<EOF | sudo tee /etc/systemd/system/amazon-ssm-agent.service.d/override.conf >/dev/null
[Service]
Environment="http_proxy=$PROXY_URL"
Environment="https_proxy=$PROXY_URL"
Environment="no_proxy=$INSTANCE_METADATA_SERVICE_IP"
EOF

    # Reload systemd daemon
    sudo systemctl daemon-reload

    # Restart SSM agent for the new configuration
    sudo systemctl restart amazon-ssm-agent
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

# Setup the .env file downloader script
setup_env_script() {
    # Create dotenv retrieval script
    cat <<EOF | sudo tee /docbox/update_env.sh >/dev/null
# Set the env file contents from the secret value
aws secretsmanager get-secret-value \
    --secret-id docbox-env-file \
    --query SecretString \
    --output text | sudo tee /docbox/.env >/dev/null
EOF

    # Make updater script executable
    sudo chmod +x /docbox/update_env.sh
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
