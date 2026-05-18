FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/conda/bin:$PATH
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_VISIBLE_DEVICES=all
# Point Vulkan loader to NVIDIA ICD (injected by nvidia container runtime)
ENV VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

# System dependencies: X11, OpenGL, Vulkan, VNC, dev tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl git unzip ca-certificates \
    # OpenGL / X11
    libgl1-mesa-glx libgl1-mesa-dri mesa-utils \
    libglvnd0 libglx0 libegl1 libgles2 libglvnd-dev \
    libglu1-mesa \
    x11-apps xauth x11-utils libxrandr-dev \
    # Vulkan loader (ICD provided by NVIDIA runtime at /usr/share/vulkan/icd.d/)
    libvulkan1 vulkan-tools \
    # Virtual display + VNC
    xvfb x11vnc \
    # noVNC web interface
    novnc websockify \
    # Window manager (minimal)
    openbox \
    # Tkinter for demo.py
    python3-tk \
    # Misc
    libglib2.0-0 libsm6 libxext6 libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda (Python 3.10)
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_24.11.1-0-Linux-x86_64.sh \
        -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -afy

# ------------------------------------------------------------------
# Create 'goodnav' conda environment
# README step 2: pytorch==2.5.1, pytorch-cuda=11.8, pandas, scipy
# ------------------------------------------------------------------
RUN /opt/conda/bin/conda create -n goodnav python=3.10 -y && \
    /opt/conda/bin/conda clean -afy

RUN /opt/conda/bin/conda run -n goodnav \
    conda install -y \
        pytorch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 \
        pytorch-cuda=11.8 \
        -c pytorch -c nvidia && \
    /opt/conda/bin/conda clean -afy

RUN /opt/conda/bin/conda run -n goodnav \
    pip install --no-cache-dir pandas scipy==1.10.1

# noVNC: ensure the vnc.html entry point exists
RUN ln -sf /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html 2>/dev/null || true

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
# demo.py is run from /workspace/IAmGoodNavigator/ (set in entrypoint)
CMD ["python", "demo.py", "--task", "fine", "--index", "0", "--work_dir", "/results"]
