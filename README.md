# Secure VPS Bootstrap

> Fast & secure VPS setup for dev/staging environments  
> Claude Code Skill for automated server configuration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 What is this?

A **Claude Code Skill** that helps you set up a new Ubuntu VPS with essential security in ~10 minutes.

**Perfect for:**
- Development servers
- Staging environments  
- Side projects
- Learning server administration

**Not for:**
- Production systems with sensitive data
- Compliance-required environments (PCI-DSS, HIPAA)
- High-availability setups

## ✨ What gets configured

### Always installed:
- ✅ SSH hardening (no root login, no passwords)
- ✅ Firewall (UFW) 
- ✅ Fail2ban (brute force protection)
- ✅ Automatic security updates
- ✅ Non-root `ops` user with sudo

### Optional components:
- 🐳 Docker + docker-compose
- 🌐 Nginx with security headers
- 🔒 Certbot (Let's Encrypt SSL)

## 🚀 Quick Start

### Option 1: Automated (recommended)

```bash
# On your NEW VPS (as root):
curl -sSL https://raw.githubusercontent.com/Zara3hustra/secure-vps-bootstrap/main/bootstrap.sh | bash
```

The script will:
1. Update system
2. Create `ops` user
3. Harden SSH
4. Configure firewall
5. Install fail2ban
6. Ask about optional components (Docker, Nginx, etc)

### Option 2: Manual

See [Full Documentation](./secure-vps-bootstrap-v0.2.md) for step-by-step manual setup.

## 📋 Prerequisites

- Fresh Ubuntu 24.04 VPS
- Root SSH access
- Your SSH public key on the server

**Missing SSH key?**

```bash
# On your local machine:
ssh-keygen -t ed25519 -C "your-email@example.com"
ssh-copy-id root@your-vps-ip
```

## 🔍 Security Check

After setup, verify everything is configured correctly:

```bash
# Download and run security check
curl -sSL https://raw.githubusercontent.com/Zara3hustra/secure-vps-bootstrap/main/security-check.sh | bash
```

Expected output:
```
✓ Root login disabled
✓ Password authentication disabled  
✓ UFW firewall is active
✓ Fail2ban is running
✓ Automatic security updates enabled
```

## 📚 Documentation

- **[Full Setup Guide](./secure-vps-bootstrap-v0.2.md)** - Complete manual installation
- **[SKILL.md](./SKILL.md)** - Claude Code integration guide
- **[Troubleshooting](#troubleshooting)** - Common issues

## 🛠️ Using with Claude Code

This is a **Claude Code Skill**. To use it:

1. Clone this repo to your skills directory
2. Claude Code will automatically detect and use it when you ask about VPS setup

Example prompts:
- "Help me set up a new VPS"
- "Configure a secure Ubuntu server"
- "I need to deploy my app to a VPS"

## 🔧 What's Included

```
secure-vps-bootstrap/
├── SKILL.md                          # Claude Code skill definition
├── secure-vps-bootstrap-v0.2.md      # Full documentation
├── bootstrap.sh                       # Automated setup script
├── security-check.sh                  # Post-install verification
├── README.md                          # This file
└── LICENSE                            # MIT License
```

## 🎓 Common Tasks

### Deploy a Docker app

```bash
# Create app directory
mkdir -p /opt/apps/myapp
cd /opt/apps/myapp

# Create docker-compose.yml
nano docker-compose.yml

# Start
docker compose up -d
```

### Deploy a Python app

```bash
# Create app directory
mkdir -p /opt/apps/myapp
cd /opt/apps/myapp

# Set up virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create systemd service (see docs)
sudo nano /etc/systemd/system/myapp.service
sudo systemctl enable myapp
sudo systemctl start myapp
```

### Get SSL certificate

```bash
# If you have a domain pointing to your VPS:
sudo certbot --nginx -d yourdomain.com
```

## 🐛 Troubleshooting

### Can't SSH after setup

**Problem:** Locked out after disabling password auth

**Solution:**
1. Access via VPS console (provider dashboard)
2. Login as root
3. Check `/home/ops/.ssh/authorized_keys` exists
4. Fix permissions: `chmod 600 /home/ops/.ssh/authorized_keys`
5. Test SSH connection: `ssh ops@your-vps-ip`

### Firewall blocked everything

```bash
# Via VPS console:
sudo ufw allow 22/tcp
sudo ufw reload
```

### Service won't start

```bash
# Check logs:
sudo journalctl -u myapp -n 50

# Check status:
sudo systemctl status myapp
```

See [full troubleshooting guide](./secure-vps-bootstrap-v0.2.md#troubleshooting) for more.

## ⚠️ Important Notes

### This is NOT production-ready

Missing for production:
- ❌ Monitoring & alerting
- ❌ Backup automation  
- ❌ Log aggregation
- ❌ Intrusion detection
- ❌ Compliance configurations

For production, you'll need additional hardening. See [upgrade guide](./secure-vps-bootstrap-v0.2.md#upgrade-to-production).

### What's secured vs not secured

**Protected against:**
- ✅ SSH brute force attacks
- ✅ Root login attempts
- ✅ Password-based authentication
- ✅ Basic DDoS (via fail2ban)
- ✅ Most common attack vectors

**Not protected against:**
- ❌ Sophisticated exploits (need monitoring)
- ❌ Application vulnerabilities (your responsibility)
- ❌ Zero-day exploits
- ❌ Social engineering

## 🤝 Contributing

Issues and pull requests welcome!

## 📄 License

MIT License - see [LICENSE](./LICENSE) file

## 🙏 Credits

Created by Alexander Sukhov

Built as a Claude Code Skill for automated VPS setup

## 📞 Support

- **Issues:** https://github.com/Zara3hustra/secure-vps-bootstrap/issues
- **Discussions:** https://github.com/Zara3hustra/secure-vps-bootstrap/discussions

---

**⭐ Star this repo if it helped you!**
