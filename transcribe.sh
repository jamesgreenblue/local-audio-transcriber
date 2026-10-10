#!/bin/bash

# Co-Authored-By: Claude Sonnet 4.6 with code review and further enhancement by Gemini Flash 3.6
# Signed-off-by: James Greenhalgh

# Resolve script directory and enforce .env presence
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: Required configuration file .env not found at $ENV_FILE"
  echo "Please copy .env.example to .env and configure your variables before running this script."
  exit 1
fi

# Load variables from .env
set -o allexport
source "$ENV_FILE"
set +o allexport

# Ensure local directories exist
mkdir -p "$AUDIO_DIR" "$OUTPUT_DIR" "$CACHE_DIR"

# Check for valid audio files before starting Docker or downloading dependencies
shopt -s nullglob
audio_files=()
for ext in ogg m4a wav mp3 OGG M4A WAV MP3; do
  audio_files+=("$AUDIO_DIR"/*."$ext")
done
shopt -u nullglob

if [ ${#audio_files[@]} -eq 0 ]; then
  echo "No valid audio files (.ogg, .m4a, .wav, .mp3) found in $AUDIO_DIR."
  exit 0
fi

# Run Docker container using interactive stdin heredoc (-i)
docker run -i --rm \
  -v "$AUDIO_DIR:/audio" \
  -v "$OUTPUT_DIR:/output" \
  -v "$CACHE_DIR:/root/.cache/huggingface" \
  -e WHISPER_MODEL="$WHISPER_MODEL" \
  -e DEVICE="$DEVICE" \
  -e COMPUTE_TYPE="$COMPUTE_TYPE" \
  -e LANGUAGE="$LANGUAGE" \
  -e BEAM_SIZE="$BEAM_SIZE" \
  -e VAD_FILTER="$VAD_FILTER" \
  -e FASTER_WHISPER_VERSION="$FASTER_WHISPER_VERSION" \
  "$PYTHON_IMAGE" bash << 'EOF'
apt-get update -yqq && apt-get install -yqq ffmpeg && pip install "$FASTER_WHISPER_VERSION" -q

python3 -u - << 'PYEOF'
import os
from faster_whisper import WhisperModel

model_name = os.environ["WHISPER_MODEL"]
device = os.environ["DEVICE"]
compute_type = os.environ["COMPUTE_TYPE"]
lang = os.environ["LANGUAGE"]
beam_size = int(os.environ["BEAM_SIZE"])
vad_filter = os.environ["VAD_FILTER"].lower() == "true"

# Map "auto" to None for language auto-detection
language = None if lang.lower() == "auto" else lang

print(f"Loading {model_name} model onto {device} ({compute_type})...")
model = WhisperModel(model_name, device=device, compute_type=compute_type)

audio_files = sorted([f for f in os.listdir("/audio") if f.lower().endswith((".ogg", ".m4a", ".wav", ".mp3"))])

for f in audio_files:
    print(f"\n--- Starting Transcription: {f} ---")
    try:
        segments, info = model.transcribe(
            "/audio/" + f,
            language=language,
            beam_size=beam_size,
            vad_filter=vad_filter
        )
        out_path = "/output/" + os.path.splitext(f)[0] + ".txt"
        
        with open(out_path, "w", encoding="utf-8") as out:
            for s in segments:
                timestamp = f"[{int(s.start // 60):02d}:{int(s.start % 60):02d}]"
                text_line = f"{timestamp} {s.text.strip()}"
                out.write(text_line + "\n")
                print(text_line)
                
        print(f"--- Completed: {f} ---")
    except Exception as e:
        print(f"Error processing {f}: {str(e)}")

print("\nAll processing complete.")
PYEOF
EOF
