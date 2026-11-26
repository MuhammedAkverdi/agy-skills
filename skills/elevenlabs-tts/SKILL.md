---
name: elevenlabs-tts
description: Generate high-quality Turkish and multilingual voiceovers, narration, and character-level timestamp alignments via the ElevenLabs REST API (`with-timestamps`), using the user's ElevenLabs account (10,000 free characters/month or paid plan) with zero browser automation latency. Use whenever a video, Reels, Short, ad, or narration needs realistic Turkish speech, narrator voiceover, or exact subtitle timing.
---

# ElevenLabs TTS & Alignment (`elevenlabs-tts`)

Generates studio-quality voiceovers (`MP3` + `alignment.json` character timestamps) in **~2 seconds** via ElevenLabs REST API — ideal as the default **Narrator / Dış Ses** engine for `gemini-reels` and `gemini-video`.

> **Hosted ElevenLabs MCP (`https://api.elevenlabs.io/v1/mcp`, OAuth):** If the user also connects ElevenLabs' hosted MCP server in `mcp_config.json`, use MCP for browsing/cloning voices or quick OAuth-backed audio calls, while keeping `tts_generate.ps1` (`/with-timestamps`) as the **primary Reels engine** because it saves `.mp3` + `.alignment.json` directly into the project folder for millisecond `.ass` subtitles.

## Safe API Key Setup (Never Print or Log Secrets)

The helper scripts resolve `ELEVENLABS_API_KEY` automatically in this order:
1. `$env:ELEVENLABS_API_KEY` (current process)
2. User environment variable `[Environment]::GetEnvironmentVariable('ELEVENLABS_API_KEY', 'User')`
3. `$env:USERPROFILE\.gemini\config\skills\elevenlabs-tts\.env` (`ELEVENLABS_API_KEY=...`)

If missing, instruct the user to set it safely once on their machine (never ask them to echo it in logs, and never print `$apiKey`):
```powershell
[Environment]::SetEnvironmentVariable("ELEVENLABS_API_KEY", "<YOUR_KEY>", "User")
```
*(Or save `ELEVENLABS_API_KEY=<YOUR_KEY>` into `$env:USERPROFILE\.gemini\config\skills\elevenlabs-tts\.env`.)*

---

## Step 0 — Quota, Voices & License Check

Before generating audio, run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\skills\elevenlabs-tts\scripts\check_quota.ps1"
```
1. Check `subscription.tier` and `subscription.remaining`.
2. Count the exact characters of your Turkish script beforehand and verify it fits inside `remaining` (a typical 4-scene Reels narrator script is ~300–450 chars out of 10,000/month).
3. Pick a suitable `voice_id` from `voices` (or a user-provided voice ID). When unsure, confirm voice choice (e.g., deep dramatic narrator vs. warm storyteller) with the user.
4. **License note:** If `tier` is `free`, remind the user briefly that ElevenLabs Free tier allows personal/non-commercial use; commercial/sponsored publishing requires a paid tier.

---

### Voice choice, pace & mix lessons (user review 2026-11-26 — mandatory)
- **Match gender/character to the content.** A male voice on a children's bedtime tale was rejected; use a warm, soft female storyteller there. Generate **2–3 one-line samples** (~80 chars each) and let the user listen (`ask_question`) before the full narration.
- **Free plan limit:** library voices (native Turkish narrators such as Zeynep `KAGDtM2gzDrjWlUp2KNe`, Melda `xtOBdZK8IsBvJfCFGpWa`, Betül Tuna `6GYyziau4Hk8qdg7od5c`, Derya `NNn9dv8zq2kUo7d3JSGG`) return `402 paid_plan_required` over the API. On free, only premade voices work (female: Sarah `EXAVITQu4vr4xnSDxMaL`, Alice `Xb7hH8MSUJpSbSDYk0k2`, **Matilda `XrExE9yKIg1WjnnlVkGX`** — chosen and approved for the v2 tale, Laura `FGY2WhTYpPnrIDTdsKH5`). Tell the user and let them choose (premade female now, or a paid plan for a native Turkish voice).
- **Pace:** `tts_generate.ps1 -Speed <0.7–1.2>` (sets `voice_settings.speed`). Children's tales **0.85–0.9**; the default 1.0 was judged too fast.
- **Mix:** narration must sit clearly above the music — see `gemini-reels` "User review" rule 1 (VO ≈ −16 LUFS, music ≈ −27…−30 LUFS with sidechain ducking, measured VO segment ≥ 8 dB above gaps).

## Step 1 — Model & Lip-Sync Strategy

- **Default model:** `eleven_multilingual_v2` — reliable, natural Turkish diction (`ç ğ ı İ ö ş ü`), consistent pacing, continuous `stability` (`0.45`), `similarity_boost` (`0.78`), `style` (`0.35`).
- **Expressive alternative:** `eleven_v3` — supports inline tags like `[whispers]`, `[sighs]`, `[tense]`. Note: `eleven_v3` requires `stability` to be exactly `0.0`, `0.5`, or `1.0` (the script omits `style` automatically when `ModelId -eq 'eleven_v3'`).
- **Lip-Sync Safety Rule:** External TTS cannot match front-facing close-up lip movement. Use ElevenLabs primarily for **Narrator / Off-screen Voiceover** (prompt Veo with `"No spoken dialogue, characters do not move their lips to speak, natural ambient sound effects only"`), or for **over-the-shoulder / silhouetted / shadowed** shots where the speaker's mouth is hidden.

---

## Step 2 — Generate Per-Scene Audio + Alignment Timestamps

Generate **one clip per scene** (`vo-01.mp3`, `vo-02.mp3`, ...) so each video scene can be trimmed tightly to `vo_dur + 0.6–0.8 s` and subtitles never drift across cuts.

**Turkish UTF-8 rule:** Always pass Turkish scripts via **`-TextFile`** saved as UTF-8 without BOM so Windows PowerShell 5.1 CLI codepages never corrupt `ç ğ ı İ ö ş ü` (`-Text` is only safe for plain ASCII):

```powershell
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$txtFile = "<project>\03-audio\vo-01.txt"
[IO.File]::WriteAllText($txtFile, "Karanlık ormanın derinliklerinde, kırmızı pelerinli kızın karşısına dev bir gölge çıktı.", $utf8NoBom)
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.gemini\config\skills\elevenlabs-tts\scripts\tts_generate.ps1" `
  -TextFile $txtFile `
  -VoiceId "<VOICE_ID>" `
  -OutPath "<project>\03-audio\vo-01.mp3" `
  -ModelId "eleven_multilingual_v2" `
  -Speed 0.88
```
Outputs created automatically:
- `vo-01.mp3` (`44.1 kHz` MP3; `ffprobe` duration printed in JSON)
- `vo-01.mp3.alignment.json` (`characters`, `character_start_times_seconds`, `character_end_times_seconds`)
- `vo-01.mp3.prompt.txt` (model, voice ID, settings, timestamp, exact text)

---

## Step 3 — Build Exact Subtitles from `*.alignment.json`

Aggregate `alignment.json` character timings into short 1–2 line phrases (by sentence/clause punctuation or ~5–7 words per cue) and shift each scene's cues by that scene's start offset (`0`, `o1`, `o2`, ...).
- Always format `.ass` with `WrapStyle: 0` + explicit `\N` line breaks, UTF-8 without BOM.
- Keep Instagram Reels Safe Zone margins: `MarginL: 90`, `MarginR: 160`, `MarginV: 480` (`x: 90..920`, `y: 260..1460`).

---

## Rules

- Never print, echo, or commit `ELEVENLABS_API_KEY` or `.env` contents.
- Never spend characters blindly on test loops — finalize the Turkish script and punctuation first, get the user's OK on text and voice (samples), verify `remaining` quota, then generate once per scene.
- Check Turkish pronunciation of proper nouns/numbers; spell tricky loanwords or numbers phonetically in Turkish if needed (e.g. `"on dokuz"` instead of `"19"`).
