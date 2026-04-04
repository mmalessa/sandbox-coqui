FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# System deps
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Create virtualenv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip
RUN pip install --upgrade pip

# Install PyTorch (CUDA)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install Coqui TTS + API server dependencies
RUN pip install TTS==0.22.0 \
    transformers==4.38.2 \
    sentencepiece \
    accelerate \
    fastapi==0.111.0 \
    uvicorn[standard]==0.29.0

# Cache dir (optional but good practice)
ENV TTS_HOME=/root/.local/share/tts

WORKDIR /app

# Expose port
EXPOSE 5002

CMD ["/opt/venv/bin/uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5002"]
