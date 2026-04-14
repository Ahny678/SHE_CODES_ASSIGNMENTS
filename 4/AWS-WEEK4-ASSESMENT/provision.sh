#!/bin/bash

# -----------------------------------------------------------
# provision.sh
# Automates EC2 instance setup for WordPress + MySQL deployment
# -----------------------------------------------------------

set -e  # Exit immediately if a command fails

# 1. Update system packages
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common \
        lsb-release

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo systemctl enable docker
else
    echo "Docker already installed."
fi

# 3. Install Docker Compose if not already installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION="2.20.2"
    sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose already installed."
fi

# 4. Create application directories
echo "Creating application directories..."
sudo mkdir -p /mnt/mysql-data
sudo mkdir -p /opt/wordpress

# 5. Detect attached EBS volume and mount if not already mounted
EBS_DEVICE="/dev/nvme1n1"    
MOUNT_POINT="/mnt/mysql-data"

if ! mount | grep -q "$MOUNT_POINT"; then
    echo "Mounting EBS volume..."
    if ! sudo blkid "$EBS_DEVICE"; then
        echo "Formatting $EBS_DEVICE as ext4..."
        sudo mkfs -t ext4 "$EBS_DEVICE"
    fi
    sudo mount "$EBS_DEVICE" "$MOUNT_POINT"
    echo "$EBS_DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
else
    echo "$MOUNT_POINT already mounted."
fi

# 6. Set ownership and permissions for Docker MySQL container
echo "Setting ownership and permissions for $MOUNT_POINT..."
sudo chown -R 1000:1000 "$MOUNT_POINT"
sudo chmod -R 770 "$MOUNT_POINT"

# 7. Install AWS CLI v2 if not installed
if ! command -v aws &> /dev/null || ! aws --version | grep -q "aws-cli/2"; then
    echo "Installing AWS CLI v2..."

    # Ensure unzip exists
    if ! command -v unzip &> /dev/null; then
        echo "Installing unzip..."
        sudo apt-get update
        sudo apt-get install -y unzip
    fi

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update

    rm -rf aws awscliv2.zip

else
    echo "AWS CLI v2 already installed."
fi

echo "Provisioning complete!"