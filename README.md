# sandbox-coqui

A Docker-based sandbox for experimenting with [Coqui TTS](https://github.com/coqui-ai/TTS) — an open-source text-to-speech library. The setup uses the multilingual **XTTS v2** model with NVIDIA GPU acceleration.

## Requirements

- Docker + Docker Compose
- NVIDIA GPU with CUDA 12.1 support
- `nvidia-container-toolkit` installed on the host

To install the NVIDIA container toolkit:

```bash
make prepare
sudo systemctl restart docker
```

## Usage

Build and start the container:

```bash
make build
make up
```

Open a shell inside the container:

```bash
make sh
```

### Text-to-speech

Put your text in `samples/input.txt`, then run:

```bash
make tts-talk
```

The output WAV file will be saved to `samples/test.wav`. The default language is Polish (`pl`) and the default speaker is `Wulf Carlevaro`.

### List available speakers

```bash
make tts-speakers
```

### Generate samples for all speakers

```bash
./speaker-test.sh
```

This iterates over every available speaker and generates a WAV file in `samples/speakers/`.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `COQUI_TOS_AGREED` | `1` | Accepts Coqui Terms of Service |
| `PYTORCH_CUDA_ALLOC_CONF` | `max_split_size_mb:128` | Limits CUDA memory fragmentation |
| `TTS_HOME` | `/root/.local/share/tts` | Model cache directory (persisted in a Docker volume) |

The TTS server (`tts-server`) is commented out in `compose.yaml` — the container defaults to `sleep infinity` for interactive use. Uncomment the `command` block to run it as an HTTP API on port `5002`.
