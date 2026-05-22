FROM nvcr.io/nvidia/isaac-sim:4.5.0

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_VISIBLE_DEVICES=all
ENV VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
ENV PATH=/opt/conda/bin:$PATH

# Display + VNC tools + tkinter
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    xvfb x11vnc \
    novnc websockify \
    openbox \
    python3-tk \
    x11-utils \
    && rm -rf /var/lib/apt/lists/*

# Miniconda (Python 3.10)
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py310_24.11.1-0-Linux-x86_64.sh \
        -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -afy

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

RUN ln -sf /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html 2>/dev/null || true

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "demo.py", "--task", "fine", "--index", "0", "--work_dir", "/results"]
