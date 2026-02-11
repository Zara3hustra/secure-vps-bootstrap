# secure-vps-bootstrap v0.2

Fast & secure VPS setup for dev/staging environments

Author: Alexander Sukhov  
License: MIT  
Focus: Quick start + essential security (not production-grade)

---

## Philosophy

**Goal:** Get a reasonably secure VPS running in 10 minutes

**Not included:** Enterprise features (monitoring, backups, compliance)  
**Included:** Protection from 95% of common attacks

**Use for:** Development, staging, side projects  
**Don't use for:** Payment processing, sensitive PII, compliance-required systems

---

## Quick Start

```bash
# 1. Initial connection (as root)
ssh root@your-vps-ip

# 2. Run bootstrap
curl -sSL https://raw.githubusercontent.com/yourusername/secure-vps-bootstrap/main/bootstrap.sh | bash

# 3. Follow prompts (3 questions total)

# 4. Done! Reconnect as ops user
ssh ops@your-vps-ip
```

---

## What Gets Installed

### Essential Security
- ✅ SSH hardening (no root, no passwords)
- ✅ Firewall (UFW)
- ✅ Auto security updates
- ✅ Fail2ban (basic config)

### Optional Stacks (you choose)
- Docker
- Nginx + SSL
- Python systemd service
- Node systemd service

---

## Manual Setup (if you prefer)

### Step 1: System Update

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw fail2ban unattended-upgrades curl git
```

### Step 2: Create User

```bash
# Create ops user
sudo adduser ops
sudo usermod -aG sudo ops

# Copy SSH key from root
sudo mkdir -p /home/ops/.ssh
sudo cp /root/.ssh/authorized_keys /home/ops/.ssh/
sudo chown -R ops:ops /home/ops/.ssh
sudo chmod 700 /home/ops/.ssh
sudo chmod 600 /home/ops/.ssh/authorized_keys
```

### Step 3: SSH Hardening

```bash
# Edit /etc/ssh/sshd_config
sudo nano /etc/ssh/sshd_config

# Set these values:
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
X11Forwarding no

# Restart SSH
sudo systemctl restart sshd
```

**⚠️ IMPORTANT:** Test new SSH connection before closing current one!

```bash
# In a NEW terminal:
ssh ops@your-vps-ip

# If it works, you can close the root session
```

### Step 4: Firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw limit OpenSSH
sudo ufw enable
```

### Step 5: Fail2ban

```bash
# Create basic config
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Step 6: Auto Updates

```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## Optional: Docker

```bash
# Install
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker ops

# Basic security
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl restart docker

# Open port if needed
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**Note:** For production, enable user namespaces (see advanced docs)

---

## Optional: Nginx + SSL

```bash
# Install
sudo apt install -y nginx certbot python3-certbot-nginx
sudo systemctl enable --now nginx
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Basic security headers
sudo tee /etc/nginx/conf.d/security.conf > /dev/null << 'EOF'
# Hide version
server_tokens off;

# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
EOF

sudo systemctl reload nginx

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d yourdomain.com

# Auto-renew
echo "0 3 * * * certbot renew --quiet --post-hook 'systemctl reload nginx'" | sudo crontab -
```

---

## Optional: Python App

```bash
# Create app structure
sudo mkdir -p /opt/apps/myapp
sudo chown ops:ops /opt/apps/myapp

# Create virtual env
cd /opt/apps/myapp
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create systemd service
sudo tee /etc/systemd/system/myapp.service > /dev/null << 'EOF'
[Unit]
Description=My Python App
After=network.target

[Service]
Type=simple
User=ops
Group=ops
WorkingDirectory=/opt/apps/myapp
Environment="PATH=/opt/apps/myapp/venv/bin"
EnvironmentFile=/opt/apps/myapp/.env
ExecStart=/opt/apps/myapp/venv/bin/python app.py
Restart=on-failure
RestartSec=5s

# Basic security
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
```

---

## Optional: Node App

```bash
# Install Node (using NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Create app structure
sudo mkdir -p /opt/apps/myapp
sudo chown ops:ops /opt/apps/myapp
cd /opt/apps/myapp
npm install

# Create systemd service
sudo tee /etc/systemd/system/myapp.service > /dev/null << 'EOF'
[Unit]
Description=My Node App
After=network.target

[Service]
Type=simple
User=ops
Group=ops
WorkingDirectory=/opt/apps/myapp
EnvironmentFile=/opt/apps/myapp/.env
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5s

# Basic security
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
```

---

## Secrets Management

```bash
# Create .env file
nano /opt/apps/myapp/.env

# Example content:
DATABASE_URL=postgresql://user:$(openssl rand -base64 24)@localhost/db
SECRET_KEY=$(openssl rand -base64 32)
API_TOKEN=$(openssl rand -hex 32)

# Secure it
chmod 600 /opt/apps/myapp/.env
chown ops:ops /opt/apps/myapp/.env

# IMPORTANT: Add to .gitignore
echo ".env" >> .gitignore
```

---

## Security Check

Run this after setup:

```bash
#!/bin/bash
echo "=== Quick Security Check ==="

# SSH
grep -q "^PermitRootLogin no" /etc/ssh/sshd_config && echo "✓ Root login disabled" || echo "✗ Root login ENABLED"
grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config && echo "✓ Password auth disabled" || echo "✗ Password auth ENABLED"

# Firewall
ufw status | grep -q "Status: active" && echo "✓ Firewall active" || echo "✗ Firewall INACTIVE"

# Fail2ban
systemctl is-active --quiet fail2ban && echo "✓ Fail2ban running" || echo "✗ Fail2ban NOT running"

# Updates
systemctl is-enabled --quiet unattended-upgrades && echo "✓ Auto-updates enabled" || echo "✗ Auto-updates NOT enabled"

echo ""
echo "If you see any ✗, fix it before deploying!"
```

---

## Common Tasks

### View logs
```bash
# SSH attempts
sudo journalctl -u ssh -n 50

# Fail2ban bans
sudo fail2ban-client status sshd

# App logs (systemd)
sudo journalctl -u myapp -f

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Restart services
```bash
sudo systemctl restart myapp
sudo systemctl restart nginx
sudo systemctl restart fail2ban
```

### Check service status
```bash
sudo systemctl status myapp
sudo systemctl status nginx
sudo systemctl status fail2ban
```

### Deploy new version
```bash
# Pull code
cd /opt/apps/myapp
git pull

# Restart service
sudo systemctl restart myapp

# Check it's running
sudo systemctl status myapp
curl http://localhost:8000/health
```

---

## Troubleshooting

### Can't SSH after hardening
**Problem:** Locked out after disabling password auth

**Solution:**
1. Use VPS console (via provider dashboard)
2. Login as root
3. Re-enable PasswordAuthentication temporarily
4. Fix your SSH keys
5. Disable passwords again

### Firewall blocking needed port
```bash
# Check current rules
sudo ufw status numbered

# Add port
sudo ufw allow 8080/tcp

# Remove port
sudo ufw delete [number]
```

### Service won't start
```bash
# Check logs
sudo journalctl -u myapp -n 50

# Common issues:
# - Wrong path in ExecStart
# - Missing EnvironmentFile
# - Port already in use
# - Permissions on files
```

### SSL certificate failed
```bash
# Check DNS is pointing to server
dig yourdomain.com

# Try again with staging (won't hit rate limits)
sudo certbot --nginx --staging -d yourdomain.com

# If staging works, get real cert
sudo certbot --nginx -d yourdomain.com
```

---

## Upgrade to Production

If your project grows and needs production-grade security:

1. **Enable Docker user namespaces**
```bash
# /etc/docker/daemon.json
{
  "userns-remap": "default"
}
```

2. **Add monitoring** (Prometheus, Grafana, or simple uptime monitoring)

3. **Add backups**
```bash
# Daily backup script
0 2 * * * tar czf /backups/app-$(date +\%Y\%m\%d).tar.gz /opt/apps
```

4. **Harden systemd services** (add ProtectSystem=strict, ReadOnlyPaths, etc)

5. **Add rate limiting** to Nginx

6. **Consider:** WAF, IDS/IPS, SIEM

See `docs/production-upgrade.md` for full guide

---

## What's NOT Included

This is a dev/staging setup. For production you also need:

- ❌ Monitoring & alerting
- ❌ Backup automation
- ❌ Log aggregation
- ❌ Intrusion detection
- ❌ Compliance configs (PCI-DSS, GDPR, SOC2)
- ❌ High availability
- ❌ Disaster recovery plan

---

## License

MIT License - see LICENSE file

---

## Version

v0.2.0 - Quick & secure bootstrap for dev/staging

## Changelog

**v0.2.0**
- Simplified for dev/staging use case
- Removed production-only complexity
- Added clear "what's not included" section
- Better troubleshooting guide

**v0.1.0**
- Initial version
