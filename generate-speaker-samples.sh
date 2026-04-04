#!/usr/bin/env bash

set -euo pipefail

API_URL="${API_URL:-http://localhost:5002/api}"
OUT_DIR="./samples/speakers"

TEXT="– Pst, słyszysz to?
– szepnął mały miś, przytulając się do pnia starej wierzby."

mkdir -p "$OUT_DIR"

echo "Fetching speakers from API..."

mapfile -t SPEAKERS < <(
  curl -sf "$API_URL/speakers" \
  | python3 -c "import sys, json; [print(s) for s in json.load(sys.stdin)['speakers']]"
)

echo "Found ${#SPEAKERS[@]} speakers"
echo

for speaker in "${SPEAKERS[@]}"; do
  [ -z "$speaker" ] && continue

  safe_name=$(echo "$speaker" | tr ' ' '_' | tr -cd '[:alnum:]_')
  out_path="$OUT_DIR/${safe_name}.wav"

  echo "Generating: $speaker"

  payload=$(python3 -c "
import json, sys
print(json.dumps({'text': sys.argv[1], 'language': 'pl', 'speaker': sys.argv[2]}))" "$TEXT" "$speaker")

  curl -sf -X POST "$API_URL/tts" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    --output "$out_path"

done

echo
echo "Done! Files saved in $OUT_DIR"
