#!/usr/bin/env bash

set -euo pipefail

DC="docker compose"
SERVICE="coqui-tts"

MODEL="tts_models/multilingual/multi-dataset/xtts_v2"
LANG="pl"
OUT_DIR="./samples/speakers"

TEXT="– Pst, słyszysz to?
– szepnął mały miś, przytulając się do pnia starej wierzby."

mkdir -p "$OUT_DIR"

echo "🔍 Fetching speakers from container..."

# 👇 pobierz i sparsuj listę speakerów do tablicy
mapfile -t SPEAKERS < <(
  $DC exec -T $SERVICE tts --model_name "$MODEL" --list_speaker_idxs \
  | sed -n "s/.*dict_keys(\[\(.*\)\]).*/\1/p" \
  | tr -d "'" \
  | tr ',' '\n' \
  | sed 's/^ *//;s/ *$//'
)

echo "📢 Found ${#SPEAKERS[@]} speakers"
echo

# 👇 iteracja po speakerach
for speaker in "${SPEAKERS[@]}"; do
  [ -z "$speaker" ] && continue

  safe_name=$(echo "$speaker" | tr ' ' '_' | tr -cd '[:alnum:]_')

  echo "🎤 Generating: $speaker"

  $DC exec -T $SERVICE tts \
    --model_name "$MODEL" \
    --text "$TEXT" \
    --language_idx "$LANG" \
    --speaker_idx "$speaker" \
    --out_path "/samples/speakers/${safe_name}.wav"

done

echo
echo "✅ Done! Files saved in ./samples/speakers"