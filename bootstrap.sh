#!/bin/bash
#
# secure-vps-bootstrap v0.2
# Quick & secure VPS setup for dev/staging
#
# Usage: curl -sSL https://raw.githubusercontent.com/.../bootstrap.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "========================================="
echo "  Secure VPS Bootstrap v0.2"
echo "  Dev/Staging Setup"
echo "========================================="
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Confirm
echo -e "${YELLOW}This will configure your VPS with basic security.${NC}"
echo "This includes:"
echo "  - Creating 'ops' user"
echo "  - Hardening SSH (no root, no passwords)"
echo "  - Enabling firewall"
echo "  - Installing fail2ban"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo -e "${GREEN}[1/6] Updating system...${NC}"
apt update
apt upgrade -y
apt install -y ufw fail2ban unattended-upgrades curl git jq

echo ""
echo -e "${GREEN}[2/6] Creating ops user...${NC}"

# Check if ops user exists
if id "ops" &>/dev/null; then
    echo "User 'ops' already exists, skipping creation."
else
    adduser --disabled-password --gecos "" ops
    usermod -aG sudo ops
    
    # Copy SSH key from root
    if [ -f /root/.ssh/authorized_keys ]; then
        mkdir -p /home/ops/.ssh
        cp /root/.ssh/authorized_keys /home/ops/.ssh/
        chown -R ops:ops /home/ops/.ssh
        chmod 700 /home/ops/.ssh
        chmod 600 /home/ops/.ssh/authorized_keys
        echo "✓ SSH key copied to ops user"
    else
        echo -e "${YELLOW}⚠ Warning: No SSH key found for root. You'll need to add one manually.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}[3/6] Configuring SSH...${NC}"

# Backup original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Update SSH config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config

# Add if not present
grep -q "^PermitRootLogin" /etc/ssh/sshd_config || echo "PermitRootLogin no" >> /etc/ssh/sshd_config
grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

echo "✓ SSH hardening applied"

echo ""
echo -e "${GREEN}[4/6] Configuring firewall...${NC}"

ufw --force default deny incoming
ufw --force default allow outgoing
ufw allow OpenSSH
ufw limit OpenSSH
ufw --force enable

echo "✓ Firewall enabled"

echo ""
echo -e "${GREEN}[5/6] Configuring fail2ban...${NC}"

# Create basic jail.local
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

systemctl enable fail2ban
systemctl restart fail2ban

echo "✓ Fail2ban configured"

echo ""
echo -e "${GREEN}[6/6] Enabling auto-updates...${NC}"

# Configure unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

dpkg-reconfigure -plow unattended-upgrades

echo "✓ Auto-updates enabled"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Basic Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"

# Ask about optional components
echo ""
echo "Do you want to install optional components?"
echo ""

# Docker
read -p "Install Docker? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Docker..."
    apt install -y docker.io docker-compose-plugin
    systemctl enable --now docker
    usermod -aG docker ops
    
    # Basic docker config
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    systemctl restart docker
    
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    echo "✓ Docker installed"
fi

# Nginx
echo ""
read -p "Install Nginx? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Nginx..."
    apt install -y nginx
    systemctl enable --now nginx
    
    # Basic security headers
    cat > /etc/nginx/conf.d/security.conf << 'EOF'
# Hide version
server_tokens off;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
EOF
    
    systemctl reload nginx
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    echo "✓ Nginx installed"
    
    # Certbot
    echo ""
    read -p "Install Certbot for SSL? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apt install -y certbot python3-certbot-nginx
        echo "✓ Certbot installed"
        echo ""
        echo "To get SSL certificate, run:"
        echo "  sudo certbot --nginx -d yourdomain.com"
    fi
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  All Done!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# Restart SSH (with warning)
echo -e "${YELLOW}⚠ IMPORTANT: SSH will restart now${NC}"
echo ""
echo "Before closing this session:"
echo "1. Open a NEW terminal"
echo "2. Test connection: ssh ops@$(hostname -I | awk '{print $1}')"
echo "3. If it works, you can close this root session"
echo ""
read -p "Press Enter to restart SSH..."

systemctl restart sshd

echo ""
echo -e "${GREEN}✓ SSH restarted${NC}"
echo ""
echo "Next steps:"
echo "  - Test SSH: ssh ops@$(hostname -I | awk '{print $1}')"
echo "  - Run security check: bash <(curl -sSL https://raw.githubusercontent.com/.../check.sh)"
echo ""
echo "Documentation: https://github.com/yourusername/secure-vps-bootstrap"
