#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILLS="$SCRIPT_DIR/skills"
TARGET_ROOT="$HOME/.gemini/config/skills"

if [ ! -d "$SOURCE_SKILLS" ]; then
  echo "Hata: skills klasoru bulunamadi: $SOURCE_SKILLS" >&2
  exit 1
fi

mkdir -p "$TARGET_ROOT"

for skill in gemini-image gemini-music gemini-video ui-design; do
  src="$SOURCE_SKILLS/$skill"
  dst="$TARGET_ROOT/$skill"

  mkdir -p "$dst"
  cp -f "$src/SKILL.md" "$dst/SKILL.md"

  # references/ klasoru varsa icerigini temiz sekilde kopyala
  if [ -d "$src/references" ]; then
    mkdir -p "$dst/references"
    cp -rf "$src/references/." "$dst/references/"
  fi

  # Mevcut usage-log.csv varsa ezme
  if [ -f "$src/usage-log.csv" ] && [ ! -f "$dst/usage-log.csv" ]; then
    cp "$src/usage-log.csv" "$dst/usage-log.csv"
  fi

  echo "[OK] /$skill kuruldu -> $dst"
done

echo ""
echo "Kurulum tamamlandi!"
echo "Antigravity'de yeni bir sohbet acarak /gemini-image, /gemini-music, /gemini-video ve /ui-design skillerini kullanabilirsiniz."
echo ""
echo "Hatirlatma:"
echo "  1. Chrome'da Google AI Pro hesabiniz acik olsun."
echo "  2. Chrome DevTools MCP baglantisi aktif olsun (chrome://inspect/#remote-debugging)."
echo "  3. Video/ses/gorsel isleme icin ffmpeg ve ffprobe kurulu olsun."
