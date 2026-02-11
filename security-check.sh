#!/bin/bash
#
# Security Check Script
# Verifies VPS is properly configured
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  VPS Security Check${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# SSH Configuration
echo "--- SSH Security ---"

if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
    echo -e "${GREEN}✓${NC} Root login disabled"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Root login ENABLED - CRITICAL"
    ((FAIL++))
fi

if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    echo -e "${GREEN}✓${NC} Password authentication disabled"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} Password authentication enabled"
    ((WARN++))
fi

if grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config; then
    echo -e "${GREEN}✓${NC} Public key authentication enabled"
    ((PASS++))
else
    echo -e "${RED}✗${NC} Public key auth DISABLED"
    ((FAIL++))
fi

# Firewall
echo ""
echo "--- Firewall ---"

if ufw status | grep -q "Status: active"; then
    echo -e "${GREEN}✓${NC} UFW firewall is active"
    ((PASS++))
    
    # Show allowed ports
    echo "  Allowed ports:"
    ufw status | grep ALLOW | awk '{print "    - " $1}'
else
    echo -e "${RED}✗${NC} UFW firewall is INACTIVE - CRITICAL"
    ((FAIL++))
fi

# Fail2ban
echo ""
echo "--- Fail2ban ---"

if systemctl is-active --quiet fail2ban; then
    echo -e "${GREEN}✓${NC} Fail2ban is running"
    ((PASS++))
    
    # Check SSH jail
    if fail2ban-client status sshd &> /dev/null; then
        BANNED=$(fail2ban-client status sshd | grep "Currently banned" | awk '{print $4}')
        echo "  SSH jail: active ($BANNED currently banned)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Fail2ban is not running"
    ((WARN++))
fi

# Auto Updates
echo ""
echo "--- Automatic Updates ---"

if systemctl is-enabled --quiet unattended-upgrades 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Automatic security updates enabled"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} Auto-updates not configured"
    ((WARN++))
fi

# Users
echo ""
echo "--- User Accounts ---"

if id "ops" &>/dev/null; then
    echo -e "${GREEN}✓${NC} User 'ops' exists"
    ((PASS++))
    
    if groups ops | grep -q sudo; then
        echo "  ops has sudo access"
    fi
else
    echo -e "${YELLOW}⚠${NC} User 'ops' not found"
    ((WARN++))
fi

# Check for passwordless sudo (potential security issue)
if [ -f /etc/sudoers.d/ops ] && grep -q "NOPASSWD" /etc/sudoers.d/ops; then
    echo -e "${YELLOW}⚠${NC} Passwordless sudo enabled for ops"
    ((WARN++))
fi

# File Permissions
echo ""
echo "--- Critical File Permissions ---"

SSHD_PERM=$(stat -c "%a" /etc/ssh/sshd_config)
if [ "$SSHD_PERM" = "600" ] || [ "$SSHD_PERM" = "644" ]; then
    echo -e "${GREEN}✓${NC} sshd_config permissions: $SSHD_PERM"
    ((PASS++))
else
    echo -e "${RED}✗${NC} sshd_config permissions: $SSHD_PERM (should be 600 or 644)"
    ((FAIL++))
fi

# Check for world-writable files
WORLD_W=$(find /opt -type f -perm -002 2>/dev/null | wc -l)
if [ $WORLD_W -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No world-writable files in /opt"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} Found $WORLD_W world-writable files in /opt"
    ((WARN++))
fi

# Docker (if installed)
if command -v docker &> /dev/null; then
    echo ""
    echo "--- Docker Security ---"
    
    echo -e "${GREEN}✓${NC} Docker is installed"
    
    # Check for running containers
    CONTAINERS=$(docker ps -q | wc -l)
    echo "  Running containers: $CONTAINERS"
    
    # Basic security checks
    if [ -f /etc/docker/daemon.json ]; then
        echo -e "${GREEN}✓${NC} Docker daemon.json exists"
        if grep -q "log-driver" /etc/docker/daemon.json; then
            echo "  Log driver configured"
        fi
    else
        echo -e "${YELLOW}⚠${NC} No docker daemon.json (logging not configured)"
        ((WARN++))
    fi
fi

# Nginx (if installed)
if command -v nginx &> /dev/null; then
    echo ""
    echo "--- Nginx Security ---"
    
    echo -e "${GREEN}✓${NC} Nginx is installed"
    
    # Check for security headers config
    if [ -f /etc/nginx/conf.d/security.conf ]; then
        echo -e "${GREEN}✓${NC} Security headers configured"
        ((PASS++))
    else
        echo -e "${YELLOW}⚠${NC} Security headers not configured"
        ((WARN++))
    fi
    
    # Check if server_tokens is off
    if grep -r "server_tokens off" /etc/nginx/ &> /dev/null; then
        echo "  Version hiding enabled"
    fi
fi

# System Updates
echo ""
echo "--- System Status ---"

# Check for available updates
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
if [ $UPDATES -eq 0 ]; then
    echo -e "${GREEN}✓${NC} System is up to date"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} $UPDATES updates available"
    ((WARN++))
fi

# Disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -lt 80 ]; then
    echo -e "${GREEN}✓${NC} Disk usage: ${DISK_USAGE}%"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} Disk usage: ${DISK_USAGE}% (getting full)"
    ((WARN++))
fi

# Recent Security Events
echo ""
echo "--- Recent Security Events ---"

# Failed SSH attempts
FAILED_SSH=$(journalctl -u ssh --since "24 hours ago" 2>/dev/null | grep -c "Failed password" || echo 0)
if [ $FAILED_SSH -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No failed SSH attempts in last 24h"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} $FAILED_SSH failed SSH attempts in last 24h"
    ((WARN++))
fi

# Fail2ban bans
if systemctl is-active --quiet fail2ban; then
    TOTAL_BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Total banned" | awk '{print $4}' || echo 0)
    if [ $TOTAL_BANNED -gt 0 ]; then
        echo "  Fail2ban has banned $TOTAL_BANNED IPs total"
    fi
fi

# Summary
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Summary${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${GREEN}Passed:${NC}  $PASS"
echo -e "${YELLOW}Warnings:${NC} $WARN"
echo -e "${RED}Failed:${NC}  $FAIL"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}⚠ CRITICAL ISSUES FOUND - FIX IMMEDIATELY${NC}"
    exit 1
elif [ $WARN -gt 3 ]; then
    echo -e "${YELLOW}⚠ Multiple warnings - review recommended${NC}"
    exit 0
else
    echo -e "${GREEN}✓ Security configuration looks good!${NC}"
    echo ""
    echo "Recommendations:"
    echo "  - Review warnings above"
    echo "  - Check logs regularly: sudo journalctl -u ssh"
    echo "  - Monitor disk space"
    echo "  - Keep system updated"
    exit 0
fi
