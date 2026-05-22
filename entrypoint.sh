#!/bin/bash
set -e

echo "========================================"
echo " Isaac Sim Navigation Demo"
echo "========================================"

# ── 1. Activate conda environment ─────────────────────────────────
source /opt/conda/etc/profile.d/conda.sh
conda activate goodnav

# ── 2. Source Isaac Sim environment (README step 2) ───────────────
#     Sets CARB_APP_PATH, EXP_PATH, ISAAC_PATH, PYTHONPATH, LD_LIBRARY_PATH
ISAACSIM_ROOT=/isaac-sim
cd "$ISAACSIM_ROOT"
source setup_conda_env.sh
cd /workspace

echo "Isaac Sim environment loaded."

# ── 3. Download demo scenes if not present ────────────────────────
# Scenes are extracted directly as kujiale_XXXX/ directories inside IAmGoodNavigator/
# download.sh does 'cd IAmGoodNavigator' internally → must be run from /workspace
SCENE_CHECK=$(ls /workspace/IAmGoodNavigator/kujiale_*/kujiale_*.usda 2>/dev/null | head -1 || echo "")
if [ -z "$SCENE_CHECK" ]; then
    echo "Demo scenes not found. Downloading..."
    cd /workspace
    bash /workspace/IAmGoodNavigator/download.sh
    echo "Demo scenes downloaded."
else
    echo "Demo scenes already present: $SCENE_CHECK"
fi

# ── 4. Display setup ──────────────────────────────────────────────
setup_vnc() {
    local VNC_DISPLAY=:99
    local VNC_PORT=5900
    local NOVNC_PORT=6080

    echo "Starting virtual display on ${VNC_DISPLAY} ..."
    rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

    Xvfb "${VNC_DISPLAY}" \
        -screen 0 1920x1080x24 \
        -ac +extension GLX +render -noreset &
    sleep 3

    export DISPLAY="${VNC_DISPLAY}"

    # Minimal window manager
    DISPLAY="${VNC_DISPLAY}" openbox --config-file /dev/null &

    # VNC server (no password)
    x11vnc \
        -display "${VNC_DISPLAY}" \
        -rfbport "${VNC_PORT}" \
        -forever -nopw -shared \
        -xkb -noxrecord -noxfixes -noxdamage \
        -quiet &

    # noVNC web interface
    websockify \
        --web /usr/share/novnc \
        "${NOVNC_PORT}" \
        "localhost:${VNC_PORT}" &

    echo "========================================"
    echo " Visualization ready!"
    echo " Browser  : http://HOST_IP:${NOVNC_PORT}/vnc_lite.html"
    echo " VNC      : HOST_IP:${VNC_PORT}"
    echo " DISPLAY  : ${VNC_DISPLAY}"
    echo "========================================"
}

if [ -n "$DISPLAY" ]; then
    if xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
        echo "Using host display: $DISPLAY"
    else
        echo "Provided DISPLAY=$DISPLAY not accessible. Falling back to Xvfb+VNC."
        setup_vnc
    fi
else
    echo "No DISPLAY set. Starting Xvfb+VNC."
    setup_vnc
fi

echo "DISPLAY=${DISPLAY}"

# ── 5. Run command ────────────────────────────────────────────────
# demo.py reads JSON files and scene dirs from os.getcwd(), so run from IAmGoodNavigator/
cd /workspace/IAmGoodNavigator
exec "$@"
