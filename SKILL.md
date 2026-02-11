# VPS Bootstrap Skill

Help users set up a secure VPS quickly and safely.

## Goal

Configure a new VPS with essential security for dev/staging environments in ~10 minutes.

## Use Cases

- Setting up a new dev/staging server
- Deploying side projects
- Creating test environments
- Learning server administration

**NOT for:** Production systems with sensitive data, compliance requirements, or high-availability needs.

## When to Use This Skill

Trigger this skill when user mentions:
- "set up new VPS"
- "configure server"
- "secure my server"
- "harden Ubuntu"
- "deploy to VPS"
- "initial server setup"

## Approach

### 1. Gather Information

Ask user 3 questions:

```
I'll help you set up a secure VPS. Quick questions:

1. Do you have SSH access to the server as root? (y/n)
2. What will you run on this server?
   - Static website/Nginx
   - Docker containers
   - Python app
   - Node.js app
   - Multiple/unsure

3. Do you have a domain name for SSL? (optional)
```

### 2. Validate Prerequisites

Before proceeding, verify:
- User has root SSH access
- Server is Ubuntu 24.04 (or compatible Debian-based)
- User has their SSH public key ready

**If missing SSH key:**
```bash
# On their local machine:
ssh-keygen -t ed25519 -C "their-email@example.com"
ssh-copy-id root@vps-ip
```

If prerequisites not met, provide setup guidance first.

### 3. Create Setup Script

Generate a custom setup script based on user's answers. Use the templates from the reference documentation.

**Always include:**
- System update
- User creation (ops)
- SSH hardening
- Firewall
- Fail2ban
- Auto-updates

**Conditionally include:**
- Docker (if containers selected)
- Nginx (if website/proxy selected)  
- Certbot (if domain provided)

### 4. Safety Protocol

**CRITICAL WARNINGS - Always show these:**

Before disabling SSH passwords:
```
⚠️ IMPORTANT: We're about to disable password authentication.

Before continuing:
1. Make sure you can SSH with your key: ssh root@your-ip
2. If that doesn't work, DON'T PROCEED - fix your SSH key first

Ready to continue? (y/n)
```

Before restarting SSH:
```
⚠️ SSH will restart in 10 seconds.

RIGHT NOW, open a NEW terminal and test:
  ssh ops@your-ip

If it works, press Enter to continue.
If it DOESN'T work, press Ctrl+C and we'll troubleshoot.
```

### 5. Execution

**Step-by-step approach:**

1. Show user the script content first
2. Ask permission to create the script on the VPS
3. Execute with clear progress messages
4. After each critical step, verify it worked
5. Provide rollback instructions if something fails

**Example:**
```bash
# Create script
cat > /tmp/vps-setup.sh << 'EOF'
[script content]
EOF

# Make executable
chmod +x /tmp/vps-setup.sh

# Run with output
bash /tmp/vps-setup.sh
```

### 6. Verification

After setup completes, create and run security check:

```bash
# Download and run security check
bash <(cat << 'EOF'
[security check script]
EOF
)
```

If check shows any FAIL status, help user fix before considering setup complete.

### 7. Post-Setup Guidance

Provide customized next steps based on their use case:

**For Docker users:**
```
Next steps:
1. Test Docker: docker run hello-world
2. Create your app directory: mkdir -p /opt/apps/myapp
3. Create docker-compose.yml
4. Deploy: docker compose up -d
```

**For Python users:**
```
Next steps:
1. Create app directory: mkdir -p /opt/apps/myapp
2. Set up virtual env: python3 -m venv /opt/apps/myapp/venv
3. Create systemd service (I can help with this)
4. Deploy your code
```

**For Nginx users:**
```
Next steps:
1. Test Nginx: curl localhost
2. Configure your site: nano /etc/nginx/sites-available/mysite
3. If you have a domain, get SSL: sudo certbot --nginx -d yourdomain.com
```

## Common Issues & Solutions

### Issue: User locked out after SSH hardening

**Symptoms:** Can't reconnect as ops user

**Solution:**
1. Access via VPS console (provider dashboard)
2. Login as root (still has password usually)
3. Check /home/ops/.ssh/authorized_keys exists and has correct permissions
4. Temporarily re-enable PasswordAuthentication to diagnose
5. Fix SSH keys, then disable passwords again

### Issue: Firewall blocks everything

**Symptoms:** Can't connect after enabling UFW

**Solution:**
```bash
# Via console:
sudo ufw allow 22/tcp
sudo ufw reload

# Or disable temporarily:
sudo ufw disable
```

### Issue: Service won't start

**Symptoms:** systemctl start myapp fails

**Common causes:**
1. Wrong path in ExecStart
2. Missing .env file
3. Port already in use
4. Permission issues

**Debug:**
```bash
sudo journalctl -u myapp -n 50
sudo systemctl status myapp
```

## Templates

### Basic Systemd Service

```ini
[Unit]
Description=My App
After=network.target

[Service]
Type=simple
User=ops
Group=ops
WorkingDirectory=/opt/apps/myapp
EnvironmentFile=/opt/apps/myapp/.env
ExecStart=/opt/apps/myapp/start.sh
Restart=on-failure
RestartSec=5s

# Basic security
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
```

### Basic Nginx Site

```nginx
server {
    listen 80;
    server_name yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Docker Compose Example

```yaml
version: '3.8'

services:
  app:
    image: myapp:latest
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

## Reference Documentation

Full setup guide is in `/mnt/skills/public/vps-bootstrap/secure-vps-bootstrap-v0.2.md`

Security check script is in `/mnt/skills/public/vps-bootstrap/security-check.sh`

Bootstrap script is in `/mnt/skills/public/vps-bootstrap/bootstrap.sh`

## Key Principles

1. **Safety First:** Always verify before making destructive changes
2. **Clear Communication:** Explain what each step does and why
3. **Provide Escape Hatches:** Show how to undo changes if needed
4. **Verify Everything:** Test each critical step before moving on
5. **Document:** Give user clear next steps and troubleshooting info

## Boundaries

**Do help with:**
- Basic server setup and hardening
- Installing standard services (Docker, Nginx, etc)
- Creating systemd services
- Troubleshooting common issues
- Security best practices for dev/staging

**Don't help with:**
- Production-grade monitoring setups (suggest external tools)
- Complex networking (VPNs, multi-server setups)
- Database administration and tuning
- Compliance configurations (PCI-DSS, HIPAA, etc)
- High-availability setups

For advanced needs, recommend:
- Full documentation: https://github.com/user/secure-vps-bootstrap
- Professional DevOps services
- Cloud-managed solutions (AWS ECS, Google Cloud Run, etc)

## Success Criteria

Setup is successful when:
1. ✅ User can SSH as ops (not root)
2. ✅ Security check script shows 0 FAIL items
3. ✅ Firewall is active
4. ✅ Fail2ban is running
5. ✅ User's chosen services are installed and running
6. ✅ User knows how to deploy their app
7. ✅ User knows where to find help if issues arise
