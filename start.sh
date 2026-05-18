#!/bin/bash
# Helper script: grant X11 access to Docker containers, then start the demo.

set -e

# Allow local X11 connections from Docker.
# Uses sudo to access the :1 display owned by another user.
echo "Granting X11 access to Docker containers on :1 ..."
sudo -u url DISPLAY=:1 XAUTHORITY=/run/user/1012/gdm/Xauthority xhost +local: 2>/dev/null || \
    DISPLAY=:1 xhost +local: 2>/dev/null || \
    echo "xhost not set (will fall back to Xvfb+VNC inside container)"

# Export the host display so the container can use it
export DISPLAY=:1

# Build if image doesn't exist yet
if ! docker image inspect vlnverse-goodnav:latest >/dev/null 2>&1; then
    echo "Image not found — building (this takes ~10-15 min first time)..."
    docker compose build
fi

echo ""
echo "Starting Isaac Sim Navigation Demo container..."
echo "If Xvfb+VNC fallback is used, connect via:"
echo "  Browser: http://$(hostname -I | awk '{print $1}'):6080/vnc_lite.html"
echo "  VNC:     $(hostname -I | awk '{print $1}'):5900"
echo ""

docker compose run --rm goodnav "$@"
