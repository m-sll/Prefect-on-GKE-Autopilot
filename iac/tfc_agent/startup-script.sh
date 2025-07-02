#!/bin/bash
set -e

# Log startup script execution
echo "Starting TFC agent setup at $(date)" | tee -a /var/log/startup-script.log

# Wait for apt to be ready
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "Waiting for apt to be ready..." | tee -a /var/log/startup-script.log
  sleep 2
done

# Update system and install prerequisites
echo "Installing prerequisites..." | tee -a /var/log/startup-script.log
apt-get update
apt-get install -y ca-certificates curl

# Remove conflicting packages if they exist
echo "Removing conflicting packages..." | tee -a /var/log/startup-script.log
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  apt-get remove -y $pkg 2>/dev/null || true
done

# Add Docker's official GPG key (new method, not using deprecated apt-key)
echo "Adding Docker GPG key..." | tee -a /var/log/startup-script.log
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to Apt sources
echo "Adding Docker repository..." | tee -a /var/log/startup-script.log
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}" ) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update apt package index
apt-get update

# Install Docker Engine, CLI, and plugins
echo "Installing Docker Engine..." | tee -a /var/log/startup-script.log
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker is installed and running
echo "Docker installed successfully" | tee -a /var/log/startup-script.log
docker --version | tee -a /var/log/startup-script.log

# Ensure Docker is enabled and started
systemctl enable docker
systemctl start docker

# Wait for Docker to be fully ready
echo "Waiting for Docker daemon to be ready..." | tee -a /var/log/startup-script.log
until docker info >/dev/null 2>&1; do
  echo "Waiting for Docker daemon..." | tee -a /var/log/startup-script.log
  sleep 2
done

# Test Docker installation
echo "Testing Docker installation..." | tee -a /var/log/startup-script.log
docker run --rm hello-world | tee -a /var/log/startup-script.log

# Create systemd service for TFC agent
echo "Creating TFC agent systemd service..." | tee -a /var/log/startup-script.log
cat > /etc/systemd/system/tfc-agent.service <<EOF
[Unit]
Description=Terraform Cloud Agent
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
RestartSec=5
Environment="TFC_AGENT_TOKEN=${tfc_agent_token}"
ExecStartPre=-/usr/bin/docker stop tfc-agent
ExecStartPre=-/usr/bin/docker rm tfc-agent
ExecStart=/usr/bin/docker run --rm --name tfc-agent \
  -e TFC_AGENT_TOKEN \
  -e TFC_AGENT_NAME=gcp-hi-agent \
  -e TFC_AGENT_LOG_LEVEL=info \
  hashicorp/tfc-agent:latest
ExecStop=/usr/bin/docker stop tfc-agent

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the TFC agent service
echo "Starting TFC agent service..." | tee -a /var/log/startup-script.log
systemctl daemon-reload
systemctl enable tfc-agent.service
systemctl start tfc-agent.service

# Wait a moment for the service to start
sleep 5

# Log the service status
echo "TFC agent service status:" | tee -a /var/log/startup-script.log
systemctl status tfc-agent.service --no-pager | tee -a /var/log/startup-script.log

# Check if container is running
echo "Docker containers:" | tee -a /var/log/startup-script.log
docker ps | tee -a /var/log/startup-script.log

# Final log entry
echo "TFC agent setup completed at $(date)" | tee -a /var/log/startup-script.log