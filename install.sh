#!/usr/bin/env bash
# Installs every skill under skills/ into ~/.gemini/config/skills/ (backs up existing ones,
# keeps an existing usage-log.csv and .env). Usage: bash install.sh [skill ...]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILLS="$SCRIPT_DIR/skills"
TARGET_ROOT="${TARGET_ROOT:-$HOME/.gemini/config/skills}"
BACKUP="$(dirname "$TARGET_ROOT")/skills-backup-$(date +%Y%m%d-%H%M%S)"

if [ ! -d "$SOURCE_SKILLS" ]; then
  echo "Hata: skills klasoru bulunamadi: $SOURCE_SKILLS" >&2
  exit 1
fi
mkdir -p "$TARGET_ROOT"

if [ "$#" -gt 0 ]; then skills=("$@"); else skills=(); for d in "$SOURCE_SKILLS"/*/; do skills+=("$(basename "$d")"); done; fi

for skill in "${skills[@]}"; do
  src="$SOURCE_SKILLS/$skill"
  dst="$TARGET_ROOT/$skill"
  [ -d "$src" ] || { echo "Atlandi (bulunamadi): $skill"; continue; }
  tmpkeep="$(mktemp -d)"
  if [ -d "$dst" ]; then
    for k in usage-log.csv .env; do if [ -f "$dst/$k" ]; then cp "$dst/$k" "$tmpkeep/$k"; fi; done
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/$skill"
  fi
  cp -R "$src" "$dst"
  for k in usage-log.csv .env; do if [ -f "$tmpkeep/$k" ]; then cp "$tmpkeep/$k" "$dst/$k"; fi; done
  rm -rf "$tmpkeep"
  echo "[OK] /$skill kuruldu -> $dst"
done
if [ -d "$BACKUP" ]; then echo "Eski surumler yedeklendi: $BACKUP"; fi

echo ""
echo "Kurulum tamamlandi! Antigravity'de yeni bir sohbet acin."
echo "Hatirlatma: Chrome'da Google AI Pro oturumu, Chrome DevTools MCP (chrome://inspect/#remote-debugging),"
echo "ffmpeg/ffprobe ve elevenlabs-tts icin ELEVENLABS_API_KEY ortam degiskeni."
echo "Not: elevenlabs-tts betikleri PowerShell (.ps1); macOS/Linux'ta 'pwsh' gerekir."
