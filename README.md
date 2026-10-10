# Local Audio Transcriber

A privacy-first, zero-cost, local audio transcription pipeline built with `faster-whisper` and Docker. Designed to run efficiently on standard CPU hardware without needing a dedicated GPU or active internet connection during processing.

## Key Features

- **Data Privacy**: 100% local execution. Audio and transcripts never leave your machine or get used for model training.
- **Works on modest hardware**: The default configuration uses `faster-whisper` with 8-bit quantization (`int8`) for fast inference on multi-core processors. The configuration can be customised for more powerful hardware.
- **VAD Silence Filtering**: Integrated Voice Activity Detection (`vad_filter=True`) automatically skips long pauses to prevent hallucinations and speed up processing.
- **Real-Time Streaming**: Unbuffered terminal logging outputs timestamps and transcribed text sentence-by-sentence as processing happens.

## Prerequisites

- **OS**: Linux (tested with ThinkPad T14 Gen 1 AMD Ryzen 5 PRO, 16GB RAM, no GPU running Ubuntu 26.04 LTS)
- **Container Engine**: [Docker](https://docs.docker.com/get-docker/) installed and runnable by non-root users
- **Supported Formats**: `.ogg`, `.m4a`, `.wav`, `.mp3`

## Quick Start

### 1. Set Up Configuration
1. Clone the repository:
```bash
git clone https://github.com/jamesgreenblue/local-audio-transcriber.git
```
2. Create your local `.env` file from the provided example:
```bash
cd local-audio-transcriber
cp .env.example .env
```
3. Grant execution permissions to the script:
```bash
chmod +x transcribe.sh
```
4. Create your audio directory (or use the path defined in your `.env`):
```bash
mkdir -p audio output model-cache
```
5. Place your source audio files into `./audio/`.
6. Execute the script:
```bash
./transcribe.sh
```

Output transcripts will be saved to `./output/<filename>.txt` with minute/second timestamp formatting.

## Configuration File Options

All execution variables are configured inside `.env`:

| Variable | Default / Example | Description |
| :--- | :--- | :--- |
| `WHISPER_MODEL` | `large-v3-turbo` | Whisper model variant (`tiny`, `small`, `medium`, `large-v3`, `large-v3-turbo`). |
| `DEVICE` | `cpu` | Processing target (`cpu`, `cuda`, `auto`). |
| `COMPUTE_TYPE` | `int8` | Numerical precision (`int8`, `int8_float16`, `float16`, `float32`). |
| `LANGUAGE` | `en` | ISO language code (e.g. `en`, `fr`, `es`) or `auto` for detection. |
| `BEAM_SIZE` | `5` | Beam search width (`1` for maximum speed, `5` for balanced accuracy). |
| `VAD_FILTER` | `True` | Strips extended silences before transcription (`True` / `False`). |
| `PYTHON_IMAGE` | `python:3.11-slim` | Base Docker image used for runtime execution. |
| `FASTER_WHISPER_VERSION` | `faster-whisper` | Package specifier (`faster-whisper` or pinned version `faster-whisper==1.1.0`). |
| `AUDIO_DIR` | `./audio` | Path to directory containing source audio files. |
| `OUTPUT_DIR` | `./output` | Path where output `.txt` transcripts will be written. |
| `CACHE_DIR` | `./model-cache` | Directory where downloaded Hugging Face model weights are saved across runs. |

## Credits

- **Signed-off-by**: James Greenhalgh
- **Co-Authored-By**: Claude Sonnet 4.6 with code review and further enhancement by Gemini Flash 3.6
