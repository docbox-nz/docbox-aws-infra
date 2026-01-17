TMP_SERVER_PATH="/tmp/docbox"
SERVER_PATH="/docbox/app"
SERVER_PATH_ALT="/docbox/app-previous"

# Download office converter server binary
curl -L -o $TMP_SERVER_PATH https://github.com/docbox-nz/docbox/releases/latest/download/docbox-aarch64-linux-gnu

# Move current docbox server binary
sudo mv $SERVER_PATH $SERVER_PATH_ALT

# Move the new docbox server binary
sudo mv $TMP_SERVER_PATH $SERVER_PATH

# Ensure the binary has execute permissions
sudo chmod +x $SERVER_PATH

# Restart the service
sudo systemctl restart docbox.service
