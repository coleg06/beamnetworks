#!/bin/bash
# This script is intended to update Cloudflared on debian machines that had Cloudflared installed via Cloudflare's generated script on their Zero Trust page. 
# I also haven't tested this on any other distro
# Make sure to change version to what version fits your install. Options include: arm32, arm64, amd32, amd64.
version="arm64"

curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$version.deb

sudo dpkg -i cloudflared.deb 

sudo systemctl restart cloudflared
