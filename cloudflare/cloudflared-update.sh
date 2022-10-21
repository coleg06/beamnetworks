#!/bin/bash
# This script is intended to update Cloudflared on debian machines that had Cloudflared installed via Cloudflare's generated script on their Zero Trust page. 
# I also haven't tested this on any other distro


curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb

sudo dpkg -i cloudflared.deb 

sudo systemctl restart cloudflared
