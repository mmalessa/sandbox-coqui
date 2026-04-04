# sandbox-coqui

A Docker-based sandbox for experimenting with [Coqui TTS](https://github.com/coqui-ai/TTS) — an open-source text-to-speech library. The setup uses the multilingual **XTTS v2** model with NVIDIA GPU acceleration, exposed as an HTTP API with a built-in Web UI.

## Requirements

- Docker + Docker Compose
- NVIDIA GPU with CUDA 12.1 support
- `nvidia-container-toolkit` installed on the host

To check whether the NVIDIA container toolkit is already installed:

```bash
make nv-check
```

To install it:

```bash
make nv-prepare
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

## Web UI

Once the container is running, open `http://localhost:5002` in your browser.

The interface lets you:
- Type text and select a speaker (alphabetically sorted) and language
- Upload a reference WAV file for zero-shot voice cloning (overrides the speaker selection)
- Tune synthesis parameters via sliders: speed, temperature, repetition penalty, length penalty, top-k, top-p
- Choose whether to play the result in the browser or download it as a WAV file

**Recommended format for reference audio:** mono, 22050 Hz, 16-bit PCM, 6–30 seconds of clean speech.

## HTTP API

The API is available at `http://localhost:5002/api`. Interactive documentation (Swagger UI) is at `http://localhost:5002/api/docs`.

| Endpoint | Description |
|---|---|
| `POST /api/tts` | Generate speech, returns `audio/wav` |
| `GET /api/speakers` | List available built-in speakers |
| `GET /api/languages` | List supported languages |
| `GET /api/health` | Health check |

Example request (see also `.http/examples.http`):

```bash
make api-tts
```

### Key synthesis parameters

| Parameter | Default | Description |
|---|---|---|
| `text` | — | Text to synthesize (required) |
| `language` | `pl` | BCP-47 language code |
| `speaker` | `Filip Traverse` | Built-in speaker name |
| `speaker_wav_base64` | `null` | Base64-encoded reference WAV for voice cloning |
| `speed` | `1.0` | Speech rate multiplier (0.1–3.0) |
| `temperature` | `0.75` | Sampling temperature — higher = more expressive |
| `repetition_penalty` | `5.0` | Penalty for repeated tokens |
| `top_k` | `50` | Top-k sampling |
| `top_p` | `0.85` | Nucleus sampling threshold |
| `do_sample` | `true` | Stochastic sampling; `false` = greedy decoding |
| `enable_text_splitting` | `true` | Split long text into sentences |

## Generate samples for all speakers

```bash
./generate-speaker-samples.sh
```

Iterates over every available speaker and saves a WAV file to `samples/speakers/`. The API URL can be overridden via the `API_URL` environment variable (default: `http://localhost:5002/api`).

## Configuration

| Variable | Default | Description |
|---|---|---|
| `COQUI_TOS_AGREED` | `1` | Accepts Coqui Terms of Service |
| `PYTORCH_CUDA_ALLOC_CONF` | `max_split_size_mb:128` | Limits CUDA memory fragmentation |
| `TTS_HOME` | `/root/.local/share/tts` | Model cache directory (persisted in a Docker volume) |
